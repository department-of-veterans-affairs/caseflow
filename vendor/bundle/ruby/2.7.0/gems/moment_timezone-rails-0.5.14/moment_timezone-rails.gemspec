# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'moment_timezone/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "moment_timezone-rails"
  spec.version       = "#{MomentTimezone::Rails::VERSION}"
  spec.authors       = ["Lim Victor"]
  spec.email         = ["github.victor@gmail.com"]
  spec.description   = "moment-timezone for Rails"
  spec.summary       = "moment-timezone-#{MomentTimezone::Rails::VERSION}"
  spec.homepage      = "https://github.com/viclim/moment_timezone-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rails", "~> 3.2"

  spec.add_runtime_dependency "momentjs-rails", "~> 2.15.1"
end
