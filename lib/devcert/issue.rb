require 'openssl'
require 'devcert/util'

module DevCert
  module Issue
    def self.issue(ca_bundle_path, domains, output_dir, key_type, rsa_key_size,
                   ec_key_size, validity)
      ca_bundle = ::DevCert::Util.load_bundle(ca_bundle_path)
      defaults = ::DevCert::Util.get_defaults
      common_name = domains[0]

      server_key = nil
      public_key = nil
      if key_type == 'rsa'
        server_key, public_key = ::DevCert::Util.generate_rsa_key(rsa_key_size)
      elsif key_type == 'ec'
        server_key, public_key = ::DevCert::Util.generate_ec_key(
          ec_key_size.to_i
        )
      else
        raise 'Unsupported key type/size'
      end

      server_name = OpenSSL::X509::Name.new [
        ['CN', common_name],
        ['O', defaults[:organization]],
        ['C', defaults[:country]],
        ['ST', defaults[:state_name]],
        ['L', defaults[:locality]]
      ]

      server_cert = OpenSSL::X509::Certificate.new
      server_cert.serial = ::DevCert::Util.generate_serial
      server_cert.version = 2
      server_cert.not_before = Time.now
      server_cert.not_after = Time.now + 60 * 60 * 24 * validity

      server_cert.subject = server_name
      server_cert.public_key = public_key
      server_cert.issuer = ca_bundle[:certificate].subject

      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = server_cert
      extension_factory.issuer_certificate = ca_bundle[:certificate]

      server_cert.add_extension(
        extension_factory.create_extension(
          'basicConstraints',
          'CA:FALSE',
          true
        )
      )
      server_cert.add_extension(
        extension_factory.create_extension(
          'keyUsage',
          'keyEncipherment,digitalSignature',
          true
        )
      )
      server_cert.add_extension(
        extension_factory.create_extension(
          'extendedKeyUsage',
          'serverAuth,clientAuth'
        )
      )
      server_cert.add_extension(
        extension_factory.create_extension(
          'subjectKeyIdentifier',
          'hash'
        )
      )
      server_cert.add_extension(
        extension_factory.create_extension(
          'subjectAltName',
          domains.map { |d| "DNS:#{d}" }.join(',')
        )
      )

      server_cert.sign(ca_bundle[:private_key], OpenSSL::Digest::SHA256.new)

      bundle_path = ::File.join(
        output_dir,
        "#{::DevCert::Util.normalize_name(common_name)}.devcert"
      )
      ::DevCert::Util.save_bundle(
        bundle_path,
        common_name,
        server_key,
        server_cert
      )
      puts "devcert bundle: #{bundle_path}"
    end
  end
end
