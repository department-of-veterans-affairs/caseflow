# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "akami/version"

Gem::Specification.new do |s|
  s.name        = "akami"
  s.version     = Akami::VERSION
  s.authors     = ["Daniel Harrington"]
  s.email       = ["me@rubiii.com"]
  s.homepage    = "https://github.com/savonrb/#{s.name}"
  s.summary     = "Web Service Security"
  s.description = "Building Web Service Security"
  s.required_ruby_version = '>= 1.9.2'

  s.rubyforge_project = s.name
  s.license = "MIT"

  s.add_dependency "gyoku", ">= 0.4.0"
  s.add_dependency "nokogiri"

  s.add_development_dependency "rake",    "~> 10.0"
  s.add_development_dependency "rspec",   "~> 2.14"
  s.add_development_dependency "timecop", "~> 0.5"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
