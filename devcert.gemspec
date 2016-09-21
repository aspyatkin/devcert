Gem::Specification.new do |s|
  s.name = 'devcert'
  s.version = '1.0.0'
  s.date = '2016-09-21'
  s.summary = 'Create development SSL/TLS certificates without a hassle'
  s.description = 'Create development SSL/TLS certificates without a hassle'
  s.authors = ['Alexander Pyatkin']
  s.email = 'aspyatkin@gmail.com'
  s.files = [
    'lib/devcert.rb',
    'lib/devcert/cli.rb',
    'lib/devcert/version.rb',
    'lib/devcert/util.rb',
    'lib/devcert/genca.rb',
    'lib/devcert/export.rb',
    'lib/devcert/issue.rb'
  ]
  s.executables = [
    'devcert'
  ]
  s.homepage = 'https://github.com/aspyatkin/devcert'
  s.license = 'MIT'

  s.required_ruby_version = '>= 2.3'

  s.add_dependency 'thor', '~> 0.19.1'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
