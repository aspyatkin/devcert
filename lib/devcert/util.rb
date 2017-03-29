require 'yaml'
require 'openssl'
require 'securerandom'

::OpenSSL::PKey::EC.send(:alias_method, :private?, :private_key?)

module DevCert
  module Util
    def self.get_defaults
      path = ::File.absolute_path('defaults.yaml', ::Dir.pwd)
      data = \
        if ::File.exist?(path)
          ::YAML.load(::File.open(path)).fetch('devcert', {})
        else
          {}
        end

      {
        organization: data.fetch('organization', 'Acme Ltd.'),
        country: data.fetch('country', 'US'),
        state_name: data.fetch('state_name', 'California'),
        locality: data.fetch('locality', 'San Francisco')
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
        io.write(bundle.to_yaml)
      end
    end

    def self.export(path, entity)
      open path, 'w' do |io|
        io.write(entity.to_pem)
      end
    end

    def self.load_bundle(path)
      full_path = ::File.absolute_path(path, __dir__)
      if ::File.exist?(full_path)
        data = ::YAML.load(::File.open(full_path))
        {
          common_name: data[:common_name],
          private_key: ::OpenSSL::PKey.read(data[:private_key]),
          certificate: ::OpenSSL::X509::Certificate.new(data[:certificate])
        }
      else
        raise "No bundle at #{full_path} exists!"
      end
    end

    def self.generate_serial
      machine_bytes = ['foo'].pack('p').size
      machine_bits = machine_bytes * 8
      machine_max_signed = 2**(machine_bits - 1) - 1
      ::SecureRandom.random_number(machine_max_signed)
    end

    def self.generate_rsa_key(size)
      key = ::OpenSSL::PKey::RSA.new(size)
      return key, key.public_key
    end

    def self.generate_ec_key(size)
      curve_name = nil
      if size == 256
        curve_name = 'prime256v1'
      elsif curve_name == 384
        curve_name = 'secp384r1'
      end

      raise 'Unsupported curve!' if curve_name.nil?

      private_key = ::OpenSSL::PKey::EC.new(curve_name)
      public_key = ::OpenSSL::PKey::EC.new(curve_name)

      private_key.generate_key
      public_key.public_key = private_key.public_key
      return private_key, public_key
    end
  end
end
