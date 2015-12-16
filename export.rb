require 'openssl'
require 'yaml'
require 'ostruct'
require 'optparse'
require './util'
require './version'

module DevCert
  module Export
    def self.parse_args(args)
      options = OpenStruct.new
      options.bundle = nil
      options.type = nil
      options.output_dir = __dir__

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: export.rb [options]'

        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('-b', '--bundle BUNDLE', 'Specify path to devcert bundle') do |bundle|
          options.bundle = bundle
        end

        opts.on('-t', '--type [TYPE]', [:private_key, :certificate],
                'Select export type (private_key, certificate)') do |type|
          options.type = type
        end

        opts.on('-o', '--output-dir DIRECTORY',
                'Specify output directory') do |output_dir|
          options.output_dir = output_dir
        end

        opts.separator ''
        opts.separator 'Common options:'

        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end

        opts.on_tail('-v', '--version', 'Show version') do
          puts "DevCert v#{::DevCert::VERSION}"
          exit
        end
      end

      begin
        opt_parser.parse!(args)
        mandatory = [:bundle, :type]
        missing = mandatory.select{ |param| options[param].nil? }
        unless missing.empty?
          puts "Missing options: #{missing.join(', ')}"
          puts opt_parser
          exit
        end
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        puts $!.to_s
        puts opt_parser
        exit
      end

      options
    end

    def self.main(bundle_path, type, output_dir)
      bundle = ::DevCert::Util::load_bundle bundle_path
      case type
      when :private_key
        private_key_path = ::File.join output_dir, "#{::DevCert::Util::normalize_name(bundle[:common_name])}_key.pem"
        ::DevCert::Util::export private_key_path, bundle[:private_key]
      when :certificate
        certificate_path = ::File.join output_dir, "#{::DevCert::Util::normalize_name(bundle[:common_name])}.crt"
        ::DevCert::Util::export certificate_path, bundle[:certificate]
      end
    end
  end
end


def main
  options = ::DevCert::Export::parse_args ARGV
  ::DevCert::Export::main options.bundle, options.type, options.output_dir
end

main
