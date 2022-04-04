# -*- encoding: utf-8 -*-
# stub: derailed_benchmarks 2.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "derailed_benchmarks".freeze
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Richard Schneeman".freeze]
  s.date = "2021-07-09"
  s.description = " Go faster, off the Rails ".freeze
  s.email = ["richard.schneeman+rubygems@gmail.com".freeze]
  s.executables = ["derailed".freeze]
  s.files = ["bin/derailed".freeze]
  s.homepage = "https://github.com/schneems/derailed_benchmarks".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Benchmarks designed to performance test your ENTIRE site".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<heapy>.freeze, ["~> 0"])
    s.add_runtime_dependency(%q<memory_profiler>.freeze, [">= 0", "< 2"])
    s.add_runtime_dependency(%q<get_process_mem>.freeze, ["~> 0"])
    s.add_runtime_dependency(%q<benchmark-ips>.freeze, ["~> 2"])
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1"])
    s.add_runtime_dependency(%q<rake>.freeze, ["> 10", "< 14"])
    s.add_runtime_dependency(%q<thor>.freeze, [">= 0.19", "< 2"])
    s.add_runtime_dependency(%q<ruby-statistics>.freeze, [">= 2.1"])
    s.add_runtime_dependency(%q<mini_histogram>.freeze, [">= 0.3.0"])
    s.add_runtime_dependency(%q<dead_end>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_development_dependency(%q<webrick>.freeze, [">= 0"])
    s.add_development_dependency(%q<capybara>.freeze, ["~> 2"])
    s.add_development_dependency(%q<m>.freeze, [">= 0"])
    s.add_development_dependency(%q<rails>.freeze, ["> 3", "<= 7"])
    s.add_development_dependency(%q<devise>.freeze, ["> 3", "< 6"])
  else
    s.add_dependency(%q<heapy>.freeze, ["~> 0"])
    s.add_dependency(%q<memory_profiler>.freeze, [">= 0", "< 2"])
    s.add_dependency(%q<get_process_mem>.freeze, ["~> 0"])
    s.add_dependency(%q<benchmark-ips>.freeze, ["~> 2"])
    s.add_dependency(%q<rack>.freeze, [">= 1"])
    s.add_dependency(%q<rake>.freeze, ["> 10", "< 14"])
    s.add_dependency(%q<thor>.freeze, [">= 0.19", "< 2"])
    s.add_dependency(%q<ruby-statistics>.freeze, [">= 2.1"])
    s.add_dependency(%q<mini_histogram>.freeze, [">= 0.3.0"])
    s.add_dependency(%q<dead_end>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<webrick>.freeze, [">= 0"])
    s.add_dependency(%q<capybara>.freeze, ["~> 2"])
    s.add_dependency(%q<m>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, ["> 3", "<= 7"])
    s.add_dependency(%q<devise>.freeze, ["> 3", "< 6"])
  end
end
