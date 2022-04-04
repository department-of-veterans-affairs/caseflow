# -*- encoding: utf-8 -*-
# stub: solargraph 0.38.0 ruby lib

Gem::Specification.new do |s|
  s.name = "solargraph".freeze
  s.version = "0.38.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fred Snyder".freeze]
  s.date = "2019-11-22"
  s.description = "IDE tools for code completion, inline documentation, and static analysis".freeze
  s.email = "admin@castwide.com".freeze
  s.executables = ["solargraph".freeze]
  s.files = ["bin/solargraph".freeze]
  s.homepage = "http://solargraph.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A Ruby language server".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<backport>.freeze, ["~> 1.1"])
    s.add_runtime_dependency(%q<bundler>.freeze, [">= 1.17.2"])
    s.add_runtime_dependency(%q<jaro_winkler>.freeze, ["~> 1.5"])
    s.add_runtime_dependency(%q<maruku>.freeze, ["~> 0.7", ">= 0.7.3"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.9", ">= 1.9.1"])
    s.add_runtime_dependency(%q<parser>.freeze, ["~> 2.3"])
    s.add_runtime_dependency(%q<reverse_markdown>.freeze, ["~> 1.0", ">= 1.0.5"])
    s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 0.52"])
    s.add_runtime_dependency(%q<thor>.freeze, ["~> 0.19", ">= 0.19.4"])
    s.add_runtime_dependency(%q<tilt>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.11.3"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 3.5.0", "~> 3.5"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.14"])
    s.add_development_dependency(%q<webmock>.freeze, ["~> 3.6"])
  else
    s.add_dependency(%q<backport>.freeze, ["~> 1.1"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.17.2"])
    s.add_dependency(%q<jaro_winkler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<maruku>.freeze, ["~> 0.7", ">= 0.7.3"])
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.9", ">= 1.9.1"])
    s.add_dependency(%q<parser>.freeze, ["~> 2.3"])
    s.add_dependency(%q<reverse_markdown>.freeze, ["~> 1.0", ">= 1.0.5"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.52"])
    s.add_dependency(%q<thor>.freeze, ["~> 0.19", ">= 0.19.4"])
    s.add_dependency(%q<tilt>.freeze, ["~> 2.0"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.11.3"])
    s.add_dependency(%q<rspec>.freeze, [">= 3.5.0", "~> 3.5"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.14"])
    s.add_dependency(%q<webmock>.freeze, ["~> 3.6"])
  end
end
