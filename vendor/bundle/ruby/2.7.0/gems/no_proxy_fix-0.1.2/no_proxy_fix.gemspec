
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'no_proxy_fix/version'

Gem::Specification.new do |spec|
  spec.name          = 'no_proxy_fix'
  spec.version       = NoProxyFix::VERSION
  spec.authors       = ['Minwoo Lee']
  spec.email         = ['ermaker@gmail.com']

  spec.summary       = 'A fix for a no_proxy bug on ruby 2.4.0 and 2.4.1'
  spec.description   = 'A fix for a no_proxy bug: https://github.com/ruby/ruby/commit/556e3da4216c926e71dea9ce4ea4a08dcfdc1275'
  spec.homepage      = 'https://github.com/ermaker/no_proxy_fix'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
end
