# -*- encoding: utf-8 -*-
# stub: validates_email_format_of 1.6.3 ruby lib

Gem::Specification.new do |s|
  s.name = "validates_email_format_of".freeze
  s.version = "1.6.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alex Dunae".freeze, "Isaac Betesh".freeze]
  s.date = "2015-08-03"
  s.description = "Validate e-mail addresses against RFC 2822 and RFC 3696.".freeze
  s.email = ["code@dunae.ca".freeze, "iybetesh@gmail.com".freeze]
  s.homepage = "https://github.com/validates-email-format-of/validates_email_format_of".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Validate e-mail addresses against RFC 2822 and RFC 3696.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<i18n>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<i18n>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end
