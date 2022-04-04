# -*- encoding: utf-8 -*-
# stub: xmldsig 0.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "xmldsig".freeze
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["benoist".freeze]
  s.date = "2015-11-17"
  s.description = "This gem is a (partial) implementation of the XMLDsig specification".freeze
  s.email = ["benoist.claassen@gmail.com".freeze]
  s.homepage = "https://github.com/benoist/xmldsig".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "This gem is a (partial) implementation of the XMLDsig specification (http://www.w3.org/TR/xmldsig-core)".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0"])
  else
    s.add_dependency(%q<nokogiri>.freeze, [">= 0"])
  end
end
