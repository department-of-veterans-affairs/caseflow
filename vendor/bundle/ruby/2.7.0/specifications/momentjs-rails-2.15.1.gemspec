# -*- encoding: utf-8 -*-
# stub: momentjs-rails 2.15.1 ruby lib

Gem::Specification.new do |s|
  s.name = "momentjs-rails".freeze
  s.version = "2.15.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Derek Prior".freeze]
  s.date = "2016-09-22"
  s.description = "    Moment.js is a lightweight javascript date library for parsing, manipulating, and formatting dates.\n    This gem allows for its easy inclusion into the rails asset pipeline.\n".freeze
  s.homepage = "https://github.com/derekprior/momentjs-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "The Moment.js JavaScript library ready to play with Rails.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<railties>.freeze, [">= 3.1"])
    s.add_development_dependency(%q<rails>.freeze, ["~> 3.2.12"])
    s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0"])
  else
    s.add_dependency(%q<railties>.freeze, [">= 3.1"])
    s.add_dependency(%q<rails>.freeze, ["~> 3.2.12"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.0"])
  end
end
