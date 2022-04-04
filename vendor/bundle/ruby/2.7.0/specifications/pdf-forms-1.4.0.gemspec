# -*- encoding: utf-8 -*-
# stub: pdf-forms 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pdf-forms".freeze
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jens Kr\u00E4mer".freeze]
  s.date = "2021-11-09"
  s.description = "A Ruby frontend to the pdftk binary, including FDF and XFDF creation. Also works with the PDFTK Java port. Just pass your template and a hash of data to fill in.".freeze
  s.email = ["jk@jkraemer.net".freeze]
  s.homepage = "http://github.com/jkraemer/pdf-forms".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Fill out PDF forms with pdftk (http://www.accesspdf.com/pdftk/).".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<cliver>.freeze, ["~> 0.3.2"])
    s.add_runtime_dependency(%q<safe_shell>.freeze, [">= 1.0.3", "< 2.0"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  else
    s.add_dependency(%q<cliver>.freeze, ["~> 0.3.2"])
    s.add_dependency(%q<safe_shell>.freeze, [">= 1.0.3", "< 2.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
  end
end
