# -*- encoding: utf-8 -*-
# stub: httpi 2.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "httpi".freeze
  s.version = "2.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze, "Martin Tepper".freeze]
  s.date = "2021-10-05"
  s.description = "Common interface for Ruby's HTTP libraries".freeze
  s.email = "me@rubiii.com".freeze
  s.homepage = "http://github.com/savonrb/httpi".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Common interface for Ruby's HTTP libraries".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<socksify>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubyntlm>.freeze, ["~> 0.3.2"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 0.13"])
    s.add_development_dependency(%q<puma>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<socksify>.freeze, [">= 0"])
    s.add_dependency(%q<rubyntlm>.freeze, ["~> 0.3.2"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_dependency(%q<mocha>.freeze, ["~> 0.13"])
    s.add_dependency(%q<puma>.freeze, ["~> 5.0"])
    s.add_dependency(%q<webmock>.freeze, [">= 0"])
  end
end
