# -*- encoding: utf-8 -*-
# stub: moment_timezone-rails 0.5.14 ruby lib

Gem::Specification.new do |s|
  s.name = "moment_timezone-rails".freeze
  s.version = "0.5.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lim Victor".freeze]
  s.date = "2018-06-06"
  s.description = "moment-timezone for Rails".freeze
  s.email = ["github.victor@gmail.com".freeze]
  s.homepage = "https://github.com/viclim/moment_timezone-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "moment-timezone-0.5.14".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rails>.freeze, ["~> 3.2"])
    s.add_runtime_dependency(%q<momentjs-rails>.freeze, ["~> 2.15.1"])
  else
    s.add_dependency(%q<rails>.freeze, ["~> 3.2"])
    s.add_dependency(%q<momentjs-rails>.freeze, ["~> 2.15.1"])
  end
end
