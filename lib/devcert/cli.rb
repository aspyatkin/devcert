require 'devcert/cli'
require 'thor'
require 'devcert/genca'
require 'devcert/export'
require 'devcert/issue'

module DevCert
  class CLI < ::Thor
    desc 'genca CA_NAME', 'Generate certification authority CA_NAME'
    method_option(
      :output,
      type: :string,
      default: ::Dir.pwd,
      aliases: '-o',
      desc: 'Output directory'
    )
    method_option(
      :key_size,
      type: :numeric,
      default: 2048,
      desc: 'RSA key size in bits'
    )
    method_option(
      :validity,
      type: :numeric,
      default: 90,
      desc: 'CA certificate validity in days'
    )
    def genca(ca_name)
      ::DevCert::GenCA.generate_ca(
        ca_name,
        options[:output],
        options[:key_size],
        options[:validity]
      )
    end

    desc 'export BUNDLE_PATH', 'Export private_key or certificate from bundle'
    method_option(
      :output,
      type: :string,
      default: ::Dir.pwd,
      aliases: '-o',
      desc: 'Output directory'
    )
    method_option(
      :type,
      enum: ['certificate', 'private_key'],
      required: true,
      aliases: '-t',
      desc: 'Export type'
    )
    def export(bundle_path)
      ::DevCert::Export.export(
        ::File.absolute_path(bundle_path, ::Dir.pwd),
        options[:type],
        options[:output]
      )
    end

    desc 'issue CA_BUNDLE_PATH', 'Issue certificates'
    method_option(
      :output,
      type: :string,
      default: ::Dir.pwd,
      aliases: '-o',
      desc: 'Output directory'
    )
    method_option(
      :domains,
      type: :array,
      required: true,
      aliases: '-d',
      desc: 'Domain list'
    )
    method_option(
      :key_size,
      type: :numeric,
      default: 2048,
      desc: 'RSA key size in bits'
    )
    method_option(
      :validity,
      type: :numeric,
      default: 90,
      desc: 'Certificate validity in days'
    )
    def issue(ca_bundle_path)
      ::DevCert::Issue.issue(
        ::File.absolute_path(ca_bundle_path, ::Dir.pwd),
        options[:domains],
        options[:output],
        options[:key_size],
        options[:validity]
      )
    end
  end
end
