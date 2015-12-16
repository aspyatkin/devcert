require 'yaml'
require 'openssl'
require 'securerandom'

module DevCert
  module Util
    def self.get_defaults
      path = ::File.absolute_path 'defaults.yaml', __dir__
      if ::File.exists? path
        data = ::YAML.load ::File.open path
      else
        data = {}
      end

      {
        organization: data.fetch('devcert', {}).fetch('organization', 'Acme Ltd.'),
        country: data.fetch('devcert', {}).fetch('country', 'US'),
        state_name: data.fetch('devcert', {}).fetch('state_name', 'California'),
        locality: data.fetch('devcert', {}).fetch('locality', 'San Francisco')
      }
    end

    def self.normalize_name(name)
      name.gsub(/[ .-]/, '_')
    end

    def self.save_bundle(path, common_name, key, cert)
      bundle = {
        common_name: common_name,
        private_key: key.to_der,
        certificate: cert.to_der
      }

      open path, 'w' do |io|
        io.write bundle.to_yaml
      end
    end

    def self.export(path, entity)
      open path, 'w' do |io|
        io.write entity.to_pem
      end
    end

    def self.load_bundle(path)
      full_path = ::File.absolute_path path, __dir__
      if ::File.exists? full_path
        data = ::YAML.load ::File.open full_path
        {
          common_name: data[:common_name],
          private_key: ::OpenSSL::PKey::RSA.new(data[:private_key]),
          certificate: ::OpenSSL::X509::Certificate.new(data[:certificate])
        }
      else
        raise "No bundle at #{full_path} exists!"
      end
    end

    def self.generate_serial
      machine_bytes = ['foo'].pack('p').size
      machine_bits = machine_bytes * 8
      machine_max_signed = 2 ** (machine_bits - 1) - 1
      SecureRandom.random_number machine_max_signed
    end
  end
end
