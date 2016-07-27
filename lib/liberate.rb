require 'liberate/version'
require 'colorize'
require 'open3'

module Liberate
  class App

    def initialize(args)
      # args.push "-h" if args.length == 0
      # Command-line options
      create_options_parser(args)
    end

    ### Creates an options parser
    def create_options_parser(args)
      args.options do |opts|
        opts.banner = "Usage: liberate <options>"
        opts.separator ''
        opts.separator "where possible options are:"

        # List devices
        opts.on('-l', '--list', 'list connected devices') do
          list_devices
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

    ### Lists connected devices
    def list_devices
      stdin, stdout, stderr, wait_thr = Open3.popen3('adb', 'devices')
      exit_code = wait_thr.value

      if (exit_code == 0)
        output = stdout.gets(nil).split("\n")
        output.delete_at(0) # DELETE this line => List of devices attached

        output.each do |line|
          device_id = line.match("([a-zA-Z0-9]+)")
          print_device_information(device_id)
        end
      else
        puts "Trouble starting 'adb', try restarting it manually.".red
        puts "Details...".yellow
        puts stdout.gets(nil)
        puts stderr.gets(nil)
        exit 1
      end
      stderr.close
      stdout.close
    end

    ### Prints device information
    def print_device_information(device_id)
      puts device_id
    end

  end
end
