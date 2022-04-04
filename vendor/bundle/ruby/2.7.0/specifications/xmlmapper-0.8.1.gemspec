# -*- encoding: utf-8 -*-
# stub: xmlmapper 0.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "xmlmapper".freeze
  s.version = "0.8.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Damien Le Berrigaud".freeze, "John Nunemaker".freeze, "David Bolton".freeze, "Roland Swingler".freeze, "Etienne Vallette d'Osia".freeze, "Franklin Webber".freeze, "Benoist Claassen".freeze, "Johnny Dongelmans".freeze]
  s.date = "2021-08-14"
  s.description = "Object to XML Mapping Library, using Nokogiri (fork from John Nunemaker's Happymapper)".freeze
  s.email = "jdongelmans@digidentity.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/digidentity/xmlmapper".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Provides a simple way to map XML to Ruby Objects and back again.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.11"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 2.8"])
  else
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.11"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.8"])
  end
end
