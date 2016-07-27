require 'colorize'
require 'liberate/version'

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

  end
end
