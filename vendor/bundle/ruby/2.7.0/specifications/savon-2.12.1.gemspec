# -*- encoding: utf-8 -*-
# stub: savon 2.12.1 ruby lib

Gem::Specification.new do |s|
  s.name = "savon".freeze
  s.version = "2.12.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze]
  s.date = "2020-07-05"
  s.description = "Heavy metal SOAP client".freeze
  s.email = "me@rubiii.com".freeze
  s.homepage = "http://savonrb.com".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Heavy metal SOAP client".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<nori>.freeze, ["~> 2.4"])
    s.add_runtime_dependency(%q<httpi>.freeze, ["~> 2.3"])
    s.add_runtime_dependency(%q<wasabi>.freeze, ["~> 3.4"])
    s.add_runtime_dependency(%q<akami>.freeze, ["~> 1.2"])
    s.add_runtime_dependency(%q<gyoku>.freeze, ["~> 1.2"])
    s.add_runtime_dependency(%q<builder>.freeze, [">= 2.1.2"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.8.1"])
    s.add_development_dependency(%q<rack>.freeze, [">= 0"])
    s.add_development_dependency(%q<puma>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.1"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 2.14"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 0.14"])
    s.add_development_dependency(%q<json>.freeze, ["~> 1.7"])
  else
    s.add_dependency(%q<nori>.freeze, ["~> 2.4"])
    s.add_dependency(%q<httpi>.freeze, ["~> 2.3"])
    s.add_dependency(%q<wasabi>.freeze, ["~> 3.4"])
    s.add_dependency(%q<akami>.freeze, ["~> 1.2"])
    s.add_dependency(%q<gyoku>.freeze, ["~> 1.2"])
    s.add_dependency(%q<builder>.freeze, [">= 2.1.2"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.8.1"])
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<puma>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.14"])
    s.add_dependency(%q<mocha>.freeze, ["~> 0.14"])
    s.add_dependency(%q<json>.freeze, ["~> 1.7"])
  end
end
