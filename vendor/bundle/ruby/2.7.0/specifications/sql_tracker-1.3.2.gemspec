# -*- encoding: utf-8 -*-
# stub: sql_tracker 1.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "sql_tracker".freeze
  s.version = "1.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Yue".freeze]
  s.date = "2021-03-05"
  s.description = "Track and analyze sql queries of your rails application".freeze
  s.email = ["jincheker@gmail.com".freeze]
  s.executables = ["sql_tracker".freeze]
  s.files = ["bin/sql_tracker".freeze]
  s.homepage = "http://www.github.com/steventen/sql_tracker".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Rails SQL Query Tracker".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
  end
end
