require 'colorize'
require 'liberate/version'

module Liberate
  class App

    def initialize(args)
      # Command-line options
      args.push "-h" if args.length == 0
      create_options_parser(args)
    end

    def create_options_parser(args)
      args.options do |opts|
        opts.banner = "Usage: liberate [OPTIONS]"
        opts.separator ''
        opts.separator "Options"

        # Help
        opts.on('-h', '--help', 'show help') do
          puts opts.help
          exit
        end

        # Version
        opts.on('-v', '--version', 'show version number') do
          puts Liberate::NAME.concat(' ').concat(Liberate::VERSION)
          exit
        end
        opts.parse!
      end
    end

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
