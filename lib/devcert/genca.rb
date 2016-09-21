require 'openssl'
require 'devcert/util'

module DevCert
  module GenCA
    def self.generate_ca(common_name, output_dir, key_size, validity)
      defaults = ::DevCert::Util.get_defaults

      ca_key = ::OpenSSL::PKey::RSA.new key_size

      ca_name = ::OpenSSL::X509::Name.new(
        [
          ['CN', common_name],
          ['O', defaults[:organization]],
          ['C', defaults[:country]],
          ['ST', defaults[:state_name]],
          ['L', defaults[:locality]]
        ]
      )

      ca_cert = ::OpenSSL::X509::Certificate.new
      ca_cert.serial = ::DevCert::Util.generate_serial
      ca_cert.version = 2
      ca_cert.not_before = ::Time.now
      ca_cert.not_after = ::Time.now + 60 * 60 * 24 * validity

      ca_cert.public_key = ca_key.public_key
      ca_cert.subject = ca_name
      ca_cert.issuer = ca_name

      extension_factory = ::OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = ca_cert
      extension_factory.issuer_certificate = ca_cert

      ca_cert.add_extension(
        extension_factory.create_extension(
          'subjectKeyIdentifier',
          'hash'
        )
      )
      ca_cert.add_extension(
        extension_factory.create_extension(
          'basicConstraints',
          'CA:TRUE,pathlen:0',
          true
        )
      )
      ca_cert.add_extension(
        extension_factory.create_extension(
          'keyUsage',
          'digitalSignature,cRLSign,keyCertSign',
          true
        )
      )
      ca_cert.add_extension(
        extension_factory.create_extension(
          'extendedKeyUsage',
          'serverAuth,clientAuth'
        )
      )

      ca_cert.sign(ca_key, ::OpenSSL::Digest::SHA256.new)

      bundle_path = ::File.join(
        output_dir,
        "#{::DevCert::Util.normalize_name(common_name)}.devcert"
      )
      ::DevCert::Util.save_bundle bundle_path, common_name, ca_key, ca_cert
      puts "devcert bundle: #{bundle_path}"
    end
  end
end
