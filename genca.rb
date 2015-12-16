require 'openssl'
require 'yaml'
require 'ostruct'
require 'optparse'
require 'securerandom'
require './util'
require './version'

module DevCert
  module GenCA
    def self.parse_args(args)
      options = OpenStruct.new
      options.common_name = nil
      options.output_dir = __dir__

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: genca.rb [options]'

        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('-n', '--common-name COMMON_NAME', 'Specify Certification Authority Common Name') do |common_name|
          options.common_name = common_name
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
        mandatory = [:common_name]
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

    def self.main(common_name, output_dir)
      defaults = ::DevCert::Util::get_defaults

      ca_key = ::OpenSSL::PKey::RSA.new 4096

      ca_name = ::OpenSSL::X509::Name.new [
        ['CN', common_name],
        ['O', defaults[:organization]],
        ['C', defaults[:country]],
        ['ST', defaults[:state_name]],
        ['L', defaults[:locality]]
      ]

      ca_cert = ::OpenSSL::X509::Certificate.new
      ca_cert.serial = ::DevCert::Util::generate_serial
      ca_cert.version = 2
      ca_cert.not_before = ::Time.now
      ca_cert.not_after = ::Time.now + 8640000

      ca_cert.public_key = ca_key.public_key
      ca_cert.subject = ca_name
      ca_cert.issuer = ca_name

      extension_factory = ::OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = ca_cert
      extension_factory.issuer_certificate = ca_cert

      ca_cert.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash')
      ca_cert.add_extension extension_factory.create_extension('basicConstraints', 'CA:TRUE,pathlen:0', true)
      ca_cert.add_extension extension_factory.create_extension('keyUsage', 'digitalSignature,cRLSign,keyCertSign', true)
      ca_cert.add_extension extension_factory.create_extension('extendedKeyUsage', 'serverAuth,clientAuth')

      ca_cert.sign ca_key, ::OpenSSL::Digest::SHA256.new

      bundle_path = ::File.join output_dir, "#{::DevCert::Util::normalize_name(common_name)}.devcert"
      ::DevCert::Util::save_bundle bundle_path, common_name, ca_key, ca_cert
      puts "devcert bundle: #{bundle_path}"
    end
  end
end


def main
  options = ::DevCert::GenCA::parse_args ARGV
  ::DevCert::GenCA::main options.common_name, options.output_dir
end

main
