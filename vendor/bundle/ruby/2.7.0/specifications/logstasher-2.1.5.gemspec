# -*- encoding: utf-8 -*-
# stub: logstasher 2.1.5 ruby lib

Gem::Specification.new do |s|
  s.name = "logstasher".freeze
  s.version = "2.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shadab Ahmed".freeze]
  s.date = "2020-12-29"
  s.description = "Awesome rails logs".freeze
  s.email = ["shadab.ansari@gmail.com".freeze]
  s.homepage = "https://github.com/shadabahmed/logstasher".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Awesome rails logs".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2"])
    s.add_runtime_dependency(%q<request_store>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.0"])
    s.add_development_dependency(%q<rails>.freeze, [">= 5.2"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 2.14"])
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 5.2"])
    s.add_dependency(%q<request_store>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.0.0"])
    s.add_dependency(%q<rails>.freeze, [">= 5.2"])
    s.add_dependency(%q<rspec>.freeze, [">= 2.14"])
  end
end
