require 'openssl'

ca_key = OpenSSL::PKey::RSA.new 4096

open 'ca_key.pem', 'w' do |io|
    io.write ca_key.to_pem
end

ca_name = OpenSSL::X509::Name.new [
    ['CN', 'Test Common Name'],
    ['O', 'Test Organization'],
    ['OU', 'Test Organization Unit'],
    ['DC', 'example'],
    ['C', 'Test Country'],
    ['ST', 'Test State Name'],
    ['L', 'Test Locality']
]

ca_cert = OpenSSL::X509::Certificate.new
ca_cert.serial = 0
ca_cert.version = 2
ca_cert.not_before = Time.now
ca_cert.not_after = Time.now + 86400

ca_cert.public_key = ca_key.public_key
ca_cert.subject = ca_name
ca_cert.issuer = ca_name

extension_factory = OpenSSL::X509::ExtensionFactory.new
extension_factory.subject_certificate = ca_cert
extension_factory.issuer_certificate = ca_cert

ca_cert.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash', true)
ca_cert.add_extension extension_factory.create_extension('basicConstraints', 'CA:TRUE,pathlen:0', true)
ca_cert.add_extension extension_factory.create_extension('keyUsage', 'digitalSignature,cRLSign,keyCertSign', true)
ca_cert.add_extension extension_factory.create_extension('extendedKeyUsage', 'serverAuth,clientAuth', true)

ca_cert.sign ca_key, OpenSSL::Digest::SHA256.new

open 'ca.crt', 'w' do |io|
    io.write ca_cert.to_pem
end


server_key = OpenSSL::PKey::RSA.new 4096
open 'server_key.pem', 'w' do |io|
    io.write server_key.to_pem
end


server_name = OpenSSL::X509::Name.new [
    ['CN', 'example.com'],
    ['O', 'Test Organization'],
    ['OU', 'Test Organization Unit'],
    ['DC', 'example'],
    ['C', 'Test Country'],
    ['ST', 'Test State Name'],
    ['L', 'Test Locality']
]

server_csr = OpenSSL::X509::Request.new
server_csr.version = 0
server_csr.subject = server_name
server_csr.public_key = server_key.public_key
server_csr.sign server_key, OpenSSL::Digest::SHA256.new

open 'server.csr', 'w' do |io|
    io.write server_csr.to_pem
end


server_cert = OpenSSL::X509::Certificate.new
server_cert.serial = 0
server_cert.version = 2
server_cert.not_before = Time.now
server_cert.not_after = Time.now + 600

server_cert.subject = server_csr.subject
server_cert.public_key = server_csr.public_key
server_cert.issuer = ca_cert.subject

extension_factory = OpenSSL::X509::ExtensionFactory.new
extension_factory.subject_certificate = server_cert
extension_factory.issuer_certificate = ca_cert

server_cert.add_extension extension_factory.create_extension('basicConstraints', 'CA:FALSE', true)
server_cert.add_extension extension_factory.create_extension('keyUsage', 'keyEncipherment,digitalSignature', true)
server_cert.add_extension extension_factory.create_extension('extendedKeyUsage', 'serverAuth,clientAuth', true)
server_cert.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash', true)
server_cert.add_extension extension_factory.create_extension('subjectAltName', 'DNS:example.com,DNS:*.example.com,DNS:example-dev.com,DNS:*.example-dev.com', true)

server_cert.sign ca_key, OpenSSL::Digest::SHA256.new

open 'server.crt', 'w' do |io|
  io.write server_cert.to_pem
end
