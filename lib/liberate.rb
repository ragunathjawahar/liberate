require 'liberate/version'
require 'optparse'
require 'colorize'
require 'open3'

module Liberate

  ### This is where all the action happens!
  class App

    # Regex
    DEVICE_ID_REGEX = "[\\w\\d\\.\\:]+"
    VALUE_SUFFIX_REGEX = "\:([a-zA-Z0-9_])+"
    IP_V4_REGEX = "([0-9])+\\.([0-9])+\\.([0-9])+\\.([0-9])+" # TODO Make a tighter regex

    # Other constants
    PORT_NUMBER = 5555
    ROW_FORMAT = '%-20s %-12s %-12s %s'

    ### Good ol' constructor
    def initialize(args)
      # args.push "-h" if args.size == 0
      # Command-line options
      create_options_parser(args)
    end

    ### Checks if 'adb' is present in the system path
    def has_adb_in_path
      unless which('adb')
        puts "'adb' (Android Debug Bridge) not found in path.".red
        exit 1
      end
    end

    ### Checks if a given command is found in the system path
    # see http://stackoverflow.com/a/5471032/421372
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        }
      end
      return nil
    end

    ### Creates an options parser
    def create_options_parser(args)
      args.options do |opts|
        opts.banner = "Usage: liberate <options>"
        opts.separator ''
        opts.separator "where possible options are:"

        # List connected devices
        opts.on('-l', '--list', 'list connected devices') do
          list_devices
          exit
        end

        # Liberate a specific device
        opts.on('-d', '--device', 'liberate a specific device') do
          if args.size == 0
            puts "You must specify a device when using the -d option.".yellow
            exit 0
          end

          liberate_device(args[0])
          exit
        end

        # Version
        opts.on('-v', '--version', 'show version number') do
          puts Liberate::NAME.concat(' ').concat(Liberate::VERSION)
          exit
        end

        # Help
        opts.on('-h', '--help', 'show help') do
          puts opts.help
          exit
        end

        opts.parse!
      end
    end

    ### Handles the -l option
    def list_devices
      devices = get_devices
      print_devices_table(devices)
    end

    ### Handles the -d option
    def liberate_device(key)
      devices = get_devices

      matching_devices = Array.new
      devices.each do |device|
        matching_devices << device if device.matches(key)
      end

      found = matching_devices.size
      if found == 0
        message = "Oops... no device matched '%s'." % [key]
        puts message.yellow
      elsif found > 1
        puts "Multiple devices found.".yellow
        puts matching_devices
      else
        device = matching_devices[0]
        liberate(device)
      end
    end

    ### Gets the list of connected devices (sorted by '@model')
    def get_devices()
      command = 'adb devices -l'
      error_message = "Trouble starting 'adb', try restarting it manually."
      console_output = execute_shell_command(command, error_message)

      console_output = console_output.split("\n")
      console_output.delete_at(0) # DELETE this line => List of devices attached
      if console_output.size == 0
        puts "No connected devices found.".yellow
        exit
      end

      # Collect and print device information
      return parse_devices(console_output)
    end

    ### Gets the list of devices from console output
    def parse_devices(console_output)
      devices = Array.new
      console_output.each do |line|
        devices << extract_device(line)
      end

      return devices.sort! { |a,b| a.model.downcase <=> b.model.downcase }
    end

    ### Get a device from the console output
    def extract_device(line)
      # Sample line => [51b64dcb    device usb:1-12 product:A6020a40 model:Lenovo_A6020a40 device:A6020a40]
      id = line.match(DEVICE_ID_REGEX)[0]
      device = extract_value("device", line)
      product = extract_value("product", line)
      model = extract_value("model", line)

      return Device.new(id, device, product, model)
    end

    ### Extracts value for the 'key' from a given console output line
    def extract_value(key, line)
      return line.match(key.concat(VALUE_SUFFIX_REGEX))[0].split(':').last
          .gsub('_', ' ')
    end

    ### Formats and prints a device table
    def print_devices_table(devices)
      # Table Header
      header = ROW_FORMAT % ['Model', 'Device', 'Product', 'ID']
      puts header.yellow

      # Table Rows
      devices.each do |d|
        row = ROW_FORMAT % [d.model, d.device, d.product, d.id]
        if d.is_connected
          puts row.light_blue
        else
          puts row
        end
      end

      # Message
      message = "#{devices.size} device(s) found."
      puts message.green
    end

    ### Liberates the specified device
    def liberate(device)
      command = "adb -s %s shell ip -f inet addr show wlan0" % [device.id]
      error_message = "Unable to connect to %s." % [device.model]
      console_output = execute_shell_command(command, error_message)

      if console_output != nil
        ip_address = extract_ip_address(console_output)
        adb_connect_tcpip(device, ip_address)
      else
        message = "WiFi is turned off on '%s', turn it on from your device's settings." % [device.model]
        puts message.yellow
      end
    end

    ### Extracts the IPv4 address from the console output
    def extract_ip_address(console_output)
      console_output = console_output.split("\n")
      console_output.each do |line|
        ip_address = line.match(IP_V4_REGEX)
        return ip_address if ip_address != nil
      end

      return nil
    end

    ### Connect to the device via its IP address and port number
    def adb_connect_tcpip(device, ip_address)
      open_tcpip(device)

      # Connect
      command = "adb -s %s connect %s:%d" % [device.id, ip_address, PORT_NUMBER]
      error_message = "Unable to connect to '%s' via %s. Are we on the same network?" % [device.model, ip_address]
      execute_shell_command(command, error_message)

      # Display message if successful!
      message = "%s liberated!" % [device.model]
      puts message.green
    end

    ### Opens a TCPIP port on the device for a remote connection
    def open_tcpip(device)
      command = "adb -s %s tcpip %d" % [device.id, PORT_NUMBER]

      error_message = "Unable to open port on '%s'." % [device.model]
      execute_shell_command(command, error_message)
    end

    ### This is an elegant method that abstracts the "Open3.popen3" call
    def execute_shell_command(command, error_message)
      stdin, stdout, stderr, wait_thr = Open3.popen3(command)

      console_output = stdout.gets(nil)
      console_error = stderr.gets(nil)
      exit_code = wait_thr.value

      # Free resources
      stdin.close
      stdout.close
      stderr.close

      if exit_code != 0
        puts error_message.red
        puts "Details...".yellow
        puts console_output
        puts console_error
        exit 1
      else
        return console_output
      end
    end

    ### Class that holds a device information
    class Device
      attr_accessor :id, :device, :product, :model

      def initialize(id, device, product, model)
        @id = id
        @device = device
        @product = product
        @model = model
      end

      def matches(key)
        key = key.downcase
        @id.downcase.include?(key) || @device.downcase.include?(key) ||
            @product.downcase.include?(key) || @model.downcase.include?(key)
      end

      def is_connected()
        @id.end_with? ":%d" % [PORT_NUMBER]
      end

      def to_s
        "ID: ".concat(@id)
            .concat(" | Device: ").concat(@device)
            .concat(" | Product: ").concat(@product)
            .concat(" | Model: ").concat(@model)
      end
    end

  end
end
