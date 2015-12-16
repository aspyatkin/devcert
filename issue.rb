require 'openssl'
require 'yaml'
require 'ostruct'
require 'optparse'
require './util'
require './version'

module DevCert
  module Issue
    def self.parse_args(args)
      options = OpenStruct.new
      options.ca_bundle = nil
      options.domains = []
      options.output_dir = __dir__

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: export.rb [options]'

        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('-c', '--ca-bundle CA_BUNDLE', 'Specify path to devcert CA bundle') do |ca_bundle|
          options.ca_bundle = ca_bundle
        end

        opts.on('-d', '--domain DOMAIN',
                'Specify domain') do |domain|
          options.domains << domain
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
        mandatory = [:ca_bundle, :domains]
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

    def self.main(ca_bundle_path, domains, output_dir)
      ca_bundle = ::DevCert::Util::load_bundle ca_bundle_path
      defaults = ::DevCert::Util::get_defaults
      common_name = domains[0]

      server_key = OpenSSL::PKey::RSA.new 4096

      server_name = OpenSSL::X509::Name.new [
          ['CN', common_name],
          ['O', defaults[:organization]],
          ['C', defaults[:country]],
          ['ST', defaults[:state_name]],
          ['L', defaults[:locality]]
      ]

      server_csr = OpenSSL::X509::Request.new
      server_csr.version = 0
      server_csr.subject = server_name
      server_csr.public_key = server_key.public_key
      server_csr.sign server_key, OpenSSL::Digest::SHA256.new

      server_cert = OpenSSL::X509::Certificate.new
      server_cert.serial = ::DevCert::Util::generate_serial
      server_cert.version = 2
      server_cert.not_before = Time.now
      server_cert.not_after = Time.now + 8640000

      server_cert.subject = server_csr.subject
      server_cert.public_key = server_csr.public_key
      server_cert.issuer = ca_bundle[:certificate].subject

      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = server_cert
      extension_factory.issuer_certificate = ca_bundle[:certificate]

      server_cert.add_extension extension_factory.create_extension('basicConstraints', 'CA:FALSE', true)
      server_cert.add_extension extension_factory.create_extension('keyUsage', 'keyEncipherment,digitalSignature', true)
      server_cert.add_extension extension_factory.create_extension('extendedKeyUsage', 'serverAuth,clientAuth')
      server_cert.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash')
      server_cert.add_extension extension_factory.create_extension('subjectAltName', domains.map{ |d| "DNS:#{d}" }.join(','))

      server_cert.sign ca_bundle[:private_key], OpenSSL::Digest::SHA256.new

      bundle_path = ::File.join output_dir, "#{::DevCert::Util::normalize_name(common_name)}.devcert"
      ::DevCert::Util::save_bundle bundle_path, common_name, server_key, server_cert
      puts "devcert bundle: #{bundle_path}"
    end
  end
end


def main
  options = ::DevCert::Issue::parse_args ARGV
  ::DevCert::Issue::main options.ca_bundle, options.domains, options.output_dir
end

main
