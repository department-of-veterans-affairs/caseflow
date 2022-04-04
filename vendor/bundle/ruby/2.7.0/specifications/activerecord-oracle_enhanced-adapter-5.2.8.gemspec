# -*- encoding: utf-8 -*-
# stub: activerecord-oracle_enhanced-adapter 5.2.8 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-oracle_enhanced-adapter".freeze
  s.version = "5.2.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.8.11".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Raimonds Simanovskis".freeze]
  s.date = "2019-12-25"
  s.description = "Oracle \"enhanced\" ActiveRecord adapter contains useful additional methods for working with new and legacy Oracle databases.\nThis adapter is superset of original ActiveRecord Oracle adapter.\n".freeze
  s.email = "raimonds.simanovskis@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "http://github.com/rsim/oracle-enhanced".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Oracle enhanced adapter for ActiveRecord".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, ["~> 5.2.0"])
    s.add_runtime_dependency(%q<ruby-plsql>.freeze, [">= 0.6.0"])
  else
    s.add_dependency(%q<activerecord>.freeze, ["~> 5.2.0"])
    s.add_dependency(%q<ruby-plsql>.freeze, [">= 0.6.0"])
  end
end
