# -*- encoding: utf-8 -*-
# stub: govdelivery-tms 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "govdelivery-tms".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["GovDelivery".freeze]
  s.date = "2020-08-17"
  s.description = "A reference implementation, written in Ruby,\n                     to interact with GovDelivery's TMS API. The client is\n                     compatible with Ruby >=2.5.8, and <= 2.7.1".freeze
  s.email = ["support@govdelivery.com".freeze]
  s.homepage = "http://govdelivery.com".freeze
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A ruby client to interact with the GovDelivery TMS REST API.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2.4.3", "< 6.0.0"])
    s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<faraday_middleware>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<mime-types>.freeze, [">= 0"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_development_dependency(%q<simplecov-cobertura>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 5.2.4.3", "< 6.0.0"])
    s.add_dependency(%q<faraday>.freeze, [">= 0"])
    s.add_dependency(%q<faraday_middleware>.freeze, [">= 0"])
    s.add_dependency(%q<mime-types>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov-cobertura>.freeze, [">= 0"])
  end
end
