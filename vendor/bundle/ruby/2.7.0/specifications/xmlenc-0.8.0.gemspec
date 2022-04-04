# -*- encoding: utf-8 -*-
# stub: xmlenc 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "xmlenc".freeze
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Benoist".freeze]
  s.date = "2021-08-23"
  s.description = "A (partial)implementation of the XMLENC specificiation".freeze
  s.email = ["bclaassen@digidentity.eu".freeze]
  s.homepage = "https://github.com/digidentity/xmlenc".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A (partial)implementation of the XMLENC specificiation".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
    s.add_runtime_dependency(%q<activemodel>.freeze, [">= 3.0.0"])
    s.add_runtime_dependency(%q<xmlmapper>.freeze, [">= 0.7.3"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.6.0", "< 2.0.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-rails>.freeze, [">= 2.14"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<activemodel>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<xmlmapper>.freeze, [">= 0.7.3"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.6.0", "< 2.0.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 2.14"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<coveralls>.freeze, [">= 0"])
  end
end
