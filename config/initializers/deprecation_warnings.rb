# frozen_string_literal: true

module DeprecationWarnings
  # Regular expressions for custom deprecation warnings that we have addressed in the codebase
  CUSTOM_DEPRECATION_WARNING_REGEXES = [
    /Caseflow::Migration is deprecated/
  ].freeze

  # Regular expressions for Rails 6.0 deprecation warnings that we have addressed in the codebase
  RAILS_6_0_FIXED_DEPRECATION_WARNING_REGEXES = [
    /Dangerous query method \(method whose arguments are used as raw SQL\) called with non\-attribute argument\(s\)/,
    /The success\? predicate is deprecated and will be removed in Rails 6\.0/
  ].freeze

  # Regular expressions for Rails 6.1 deprecation warnings that we have addressed in the codebase
  RAILS_6_1_FIXED_DEPRECATION_WARNING_REGEXES = [
    /update_attributes is deprecated and will be removed from Rails 6\.1/,
    /ActionView::Base instances should be constructed with a lookup context, assignments, and a controller./,
    /ActionView::Base instances must implement `compiled_method_container`/,
    /render file: should be given the absolute path to a file/,
    /`ActiveRecord::Result#to_hash` has been renamed to `to_a`/,
    /Class level methods will no longer inherit scoping/,
    /Controller-level `force_ssl` is deprecated and will be removed from Rails 6\.1/,
    /NOT conditions will no longer behave as NOR in Rails 6\.1/
  ].freeze

  # Regular expressions for deprecation warnings that should raise an exception on detection
  DISALLOWED_DEPRECATION_WARNING_REGEXES = [
    *CUSTOM_DEPRECATION_WARNING_REGEXES,
    *RAILS_6_0_FIXED_DEPRECATION_WARNING_REGEXES,
    *RAILS_6_1_FIXED_DEPRECATION_WARNING_REGEXES
  ].freeze
end
