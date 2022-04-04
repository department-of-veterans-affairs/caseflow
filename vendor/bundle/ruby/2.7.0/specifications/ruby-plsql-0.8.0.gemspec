# -*- encoding: utf-8 -*-
# stub: ruby-plsql 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-plsql".freeze
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Raimonds Simanovskis".freeze]
  s.date = "2021-08-10"
  s.description = "  ruby-plsql gem provides simple Ruby API for calling Oracle PL/SQL procedures.\n  It could be used both for accessing Oracle PL/SQL API procedures in legacy applications\n  as well as it could be used to create PL/SQL unit tests using Ruby testing libraries.\n".freeze
  s.email = "raimonds.simanovskis@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "http://github.com/rsim/ruby-plsql".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Ruby API for calling Oracle PL/SQL procedures.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<juwelier>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["= 0.81"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop-rails>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 10.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1"])
    s.add_development_dependency(%q<activerecord>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<activerecord-oracle_enhanced-adapter>.freeze, ["~> 1.7"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_development_dependency(%q<ruby-oci8>.freeze, ["~> 2.1"])
  else
    s.add_dependency(%q<juwelier>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.81"])
    s.add_dependency(%q<rubocop-performance>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop-rails>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.1"])
    s.add_dependency(%q<activerecord>.freeze, ["~> 5.0"])
    s.add_dependency(%q<activerecord-oracle_enhanced-adapter>.freeze, ["~> 1.7"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<ruby-oci8>.freeze, ["~> 2.1"])
  end
end
