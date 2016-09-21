require 'devcert/util'

module DevCert
  module Export
    def self.export(bundle_path, type, output_dir)
      bundle = ::DevCert::Util.load_bundle bundle_path
      case type
      when 'private_key'
        private_key_path = ::File.join(
          output_dir,
          "#{::DevCert::Util.normalize_name(bundle[:common_name])}_key.pem"
        )
        ::DevCert::Util.export(private_key_path, bundle[:private_key])
        puts "file: #{private_key_path}"
      when 'certificate'
        certificate_path = ::File.join(
          output_dir,
          "#{::DevCert::Util.normalize_name(bundle[:common_name])}.crt"
        )
        ::DevCert::Util.export(certificate_path, bundle[:certificate])
        puts "file: #{certificate_path}"
      end
    end
  end
end
