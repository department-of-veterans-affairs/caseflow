# -*- encoding: utf-8 -*-
# stub: holidays 6.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "holidays".freeze
  s.version = "6.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alex Dunae".freeze, "Phil Peble".freeze]
  s.date = "2018-10-13"
  s.description = "A collection of Ruby methods to deal with statutory and other holidays. You deserve a holiday!".freeze
  s.email = ["holidaysgem@gmail.com".freeze]
  s.homepage = "https://github.com/holidays/holidays".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A collection of Ruby methods to deal with statutory and other holidays.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.16"])
    s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.2"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 1.7"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.11"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.16"])
    s.add_dependency(%q<rake>.freeze, ["~> 12"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.16"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.2"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.7"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.11"])
  end
end
