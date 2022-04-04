# -*- encoding: utf-8 -*-
# stub: wasabi 3.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wasabi".freeze
  s.version = "3.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/savonrb/wasabi/issues", "changelog_uri" => "https://github.com/savonrb/wasabi/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/wasabi/3.7.0", "source_code_uri" => "https://github.com/savonrb/wasabi" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze]
  s.date = "2022-01-25"
  s.description = "A simple WSDL parser".freeze
  s.email = ["me@rubiii.com".freeze]
  s.homepage = "https://github.com/savonrb/wasabi".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A simple WSDL parser".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<httpi>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.4.2"])
    s.add_runtime_dependency(%q<addressable>.freeze, [">= 0"])
  else
    s.add_dependency(%q<httpi>.freeze, ["~> 2.0"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.4.2"])
    s.add_dependency(%q<addressable>.freeze, [">= 0"])
  end
end
