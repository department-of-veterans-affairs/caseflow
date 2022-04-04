# -*- encoding: utf-8 -*-
# stub: redis-activesupport 5.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-activesupport".freeze
  s.version = "5.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze, "Ryan Bigg".freeze]
  s.date = "2022-01-17"
  s.description = "Redis store for ActiveSupport".freeze
  s.email = ["me@lucaguidi.com".freeze, "me@ryanbigg.com".freeze]
  s.homepage = "http://redis-store.org/redis-activesupport".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Redis store for ActiveSupport".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<redis-store>.freeze, [">= 1.3", "< 2"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3", "< 8"])
    s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 0.14.0"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 4.2", "< 6"])
    s.add_development_dependency(%q<connection_pool>.freeze, ["= 2.2.2"])
    s.add_development_dependency(%q<redis-store-testing>.freeze, [">= 0"])
    s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<pry-byebug>.freeze, ["~> 3"])
  else
    s.add_dependency(%q<redis-store>.freeze, [">= 1.3", "< 2"])
    s.add_dependency(%q<activesupport>.freeze, [">= 3", "< 8"])
    s.add_dependency(%q<rake>.freeze, [">= 12.3.3"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, ["~> 0.14.0"])
    s.add_dependency(%q<minitest>.freeze, [">= 4.2", "< 6"])
    s.add_dependency(%q<connection_pool>.freeze, ["= 2.2.2"])
    s.add_dependency(%q<redis-store-testing>.freeze, [">= 0"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.0"])
    s.add_dependency(%q<pry-byebug>.freeze, ["~> 3"])
  end
end
