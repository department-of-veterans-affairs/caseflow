ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
ENV["NLS_LANG"] = "AMERICAN_AMERICA.UTF8"

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Pull this in before any other non-bundler/bootsnap gem to avoid SIGSEGV
# during Oracle connection setup on arm64 architecture.
require 'ruby-oci8'
