$:.push File.expand_path('../lib', __FILE__)
require 'xmlenc/version'

Gem::Specification.new do |spec|
  spec.name          = 'xmlenc'
  spec.version       = Xmlenc::VERSION
  spec.authors       = ['Benoist']
  spec.email         = ['bclaassen@digidentity.eu']
  spec.description   = 'A (partial)implementation of the XMLENC specificiation'
  spec.summary       = 'A (partial)implementation of the XMLENC specificiation'
  spec.homepage      = 'https://github.com/digidentity/xmlenc'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '>= 3.0.0'
  spec.add_runtime_dependency 'activemodel', '>= 3.0.0'
  spec.add_runtime_dependency 'xmlmapper', '>= 0.7.3'
  spec.add_runtime_dependency 'nokogiri', '>= 1.6.0', '< 2.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec-rails', '>= 2.14'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'coveralls'
end
