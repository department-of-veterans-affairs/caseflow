# -*- encoding: utf-8 -*-
# stub: paper_trail 10.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "paper_trail".freeze
  s.version = "10.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andy Stewart".freeze, "Ben Atkins".freeze, "Jared Beck".freeze]
  s.date = "2019-07-31"
  s.description = "Track changes to your models, for auditing or versioning. See how a model looked\nat any stage in its lifecycle, revert it to any version, or restore it after it\nhas been destroyed.\n".freeze
  s.email = "jared@jaredbeck.com".freeze
  s.homepage = "https://github.com/paper-trail-gem/paper_trail".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Track changes to your models.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.2"])
    s.add_runtime_dependency(%q<request_store>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.2"])
    s.add_development_dependency(%q<byebug>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<ffaker>.freeze, ["~> 2.8"])
    s.add_development_dependency(%q<generator_spec>.freeze, ["~> 0.9.4"])
    s.add_development_dependency(%q<memory_profiler>.freeze, ["~> 0.9.12"])
    s.add_development_dependency(%q<mysql2>.freeze, ["~> 0.5.2"])
    s.add_development_dependency(%q<paper_trail-association_tracking>.freeze, ["~> 2.0.0"])
    s.add_development_dependency(%q<pg>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.3"])
    s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.8"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.71.0"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.3.0"])
    s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.33.0"])
    s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3.13"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 4.2"])
    s.add_dependency(%q<request_store>.freeze, ["~> 1.1"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.2"])
    s.add_dependency(%q<byebug>.freeze, ["~> 10.0"])
    s.add_dependency(%q<ffaker>.freeze, ["~> 2.8"])
    s.add_dependency(%q<generator_spec>.freeze, ["~> 0.9.4"])
    s.add_dependency(%q<memory_profiler>.freeze, ["~> 0.9.12"])
    s.add_dependency(%q<mysql2>.freeze, ["~> 0.5.2"])
    s.add_dependency(%q<paper_trail-association_tracking>.freeze, ["~> 2.0.0"])
    s.add_dependency(%q<pg>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.3"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.8"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.71.0"])
    s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.3.0"])
    s.add_dependency(%q<rubocop-rspec>.freeze, ["~> 1.33.0"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3.13"])
  end
end
