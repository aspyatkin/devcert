# devcert
A tool for creation X509 certificates without a hassle.

**WIP**

## Prehistory
OpenSSL has way too many command line switches to generate a self-signed CA certificate and then to sign development server certificates with it. Therefore I decided to create tiny Ruby utilities to simplify these tasks.

## Installation
```
$ gem install devcert
```

## Usage
All examples below assume that you're in `devcert` directory. Note that certificate generation produces `*.devcert` file. It contains certificate's common name, private key and certificate in DER format.
### Generating CA certificate
```
$ devcert genca "Acme Ltd."
```
The command above will create a file named `Acme_Ltd_.devcert` in the current directory.

### Issuing server certificate
```
$ devcert issue Acme_Ltd_.devcert -d acme.dev www.acme.dev api.acme.dev
```
The command above will create a file named `acme_dev.devcert` (after first domain in the list) in the current directory.

### Exporting certificates/private keys
`*.devcert` bundles aren't suitable when you are about to upload generated certificates on your development server.

To export a certificate, run
```
$ devcert export acme_dev.devcert -t certificate
```
The command above will create a file named `acme_dev.crt` in the current directory.

To export a private key, run
```
$ devcert export acme_dev.devcert -t private_key
```
The command above will create a file named `acme_dev_key.pem` in the current directory.

Don't forget to add corresponding CA certificate to system/browser certificate store as a "Trusted Root Authority".

### Tips
Use `-o` (`--output-dir`) to specify another directory for generated `*.devcert` files/exported certificates/exported private keys instead of current directory.

## Security considerations
Under no circumstances should you use this tool for production X509 certificates.

`*.devcert` file contains both certificate and unencrypted private key.
Use this tool only for development-purpose certificates.

## License
MIT @ [Alexander Pyatkin](https://github.com/aspyatkin)
