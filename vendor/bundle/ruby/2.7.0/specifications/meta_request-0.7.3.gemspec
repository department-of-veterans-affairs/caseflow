# -*- encoding: utf-8 -*-
# stub: meta_request 0.7.3 ruby lib

Gem::Specification.new do |s|
  s.name = "meta_request".freeze
  s.version = "0.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dejan Simic".freeze]
  s.date = "2021-09-05"
  s.description = "Supporting gem for Rails Panel (Google Chrome extension for Rails development)".freeze
  s.email = "desimic@gmail.com".freeze
  s.homepage = "https://github.com/dejan/rails_panel/tree/master/meta_request".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Request your Rails request".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack-contrib>.freeze, [">= 1.1", "< 3"])
    s.add_runtime_dependency(%q<railties>.freeze, [">= 3.0.0", "< 7"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8.0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.74.0"])
  else
    s.add_dependency(%q<rack-contrib>.freeze, [">= 1.1", "< 3"])
    s.add_dependency(%q<railties>.freeze, [">= 3.0.0", "< 7"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.8.0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.74.0"])
  end
end
