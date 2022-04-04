# -*- encoding: utf-8 -*-
# stub: ddtrace 0.54.2 ruby lib
# stub: ext/ddtrace_profiling_native_extension/extconf.rb

Gem::Specification.new do |s|
  s.name = "ddtrace".freeze
  s.version = "0.54.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Datadog, Inc.".freeze]
  s.date = "2022-01-18"
  s.description = "ddtrace is Datadog\u2019s tracing client for Ruby. It is used to trace requests\nas they flow across web servers, databases and microservices so that developers\nhave great visiblity into bottlenecks and troublesome requests.\n".freeze
  s.email = ["dev@datadoghq.com".freeze]
  s.executables = ["ddtracerb".freeze]
  s.extensions = ["ext/ddtrace_profiling_native_extension/extconf.rb".freeze]
  s.files = ["bin/ddtracerb".freeze, "ext/ddtrace_profiling_native_extension/extconf.rb".freeze]
  s.homepage = "https://github.com/DataDog/dd-trace-rb".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.1.0".freeze, "< 3.2".freeze])
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Datadog tracing code for your Ruby applications".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<msgpack>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<debase-ruby_core_source>.freeze, ["<= 0.10.14"])
  else
    s.add_dependency(%q<msgpack>.freeze, [">= 0"])
    s.add_dependency(%q<debase-ruby_core_source>.freeze, ["<= 0.10.14"])
  end
end
