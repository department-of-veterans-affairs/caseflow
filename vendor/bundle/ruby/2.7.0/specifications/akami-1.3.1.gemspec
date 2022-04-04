# -*- encoding: utf-8 -*-
# stub: akami 1.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "akami".freeze
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze]
  s.date = "2015-05-24"
  s.description = "Building Web Service Security".freeze
  s.email = ["me@rubiii.com".freeze]
  s.homepage = "https://github.com/savonrb/akami".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Web Service Security".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<gyoku>.freeze, [">= 0.4.0"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 2.14"])
    s.add_development_dependency(%q<timecop>.freeze, ["~> 0.5"])
  else
    s.add_dependency(%q<gyoku>.freeze, [">= 0.4.0"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.14"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.5"])
  end
end
