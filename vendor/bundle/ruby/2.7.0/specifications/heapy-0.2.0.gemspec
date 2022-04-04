# -*- encoding: utf-8 -*-
# stub: heapy 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "heapy".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["schneems".freeze]
  s.date = "2020-08-26"
  s.description = "Got a heap dump? Great. Use this tool to see what's in it!".freeze
  s.email = ["richard.schneeman@gmail.com".freeze]
  s.executables = ["heapy".freeze]
  s.files = ["bin/heapy".freeze]
  s.homepage = "https://github.com/schneems/heapy".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Inspects Ruby heap dumps".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<thor>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, ["> 1"])
    s.add_development_dependency(%q<rake>.freeze, ["> 10.0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<thor>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["> 1"])
    s.add_dependency(%q<rake>.freeze, ["> 10.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end
