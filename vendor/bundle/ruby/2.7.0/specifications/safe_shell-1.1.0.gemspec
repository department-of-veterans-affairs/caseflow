# -*- encoding: utf-8 -*-
# stub: safe_shell 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "safe_shell".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Envato".freeze, "Ian Leitch".freeze, "Pete Yandell".freeze]
  s.date = "2017-06-26"
  s.description = "Execute shell commands and get the resulting output, but without the security problems of Ruby\u2019s backtick operator.".freeze
  s.email = ["pete@notahat.com".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://github.com/envato/safe_shell".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Safely execute shell commands and get their output.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end
