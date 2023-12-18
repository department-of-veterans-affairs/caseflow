# frozen_string_literal: true

# @note Temporary solution for disallowed deprecation warnings.
#   To be replaced by ActiveSupport Disallowed Deprecations after upgrading to Rails 6.1:
#   https://rubyonrails.org/2020/12/9/Rails-6-1-0-release#disallowed-deprecation-support
module DisallowedDeprecations
  class ::DisallowedDeprecationError < StandardError; end

  # Regular expressions for Rails 6.0 deprecation warnings that we have addressed in the codebase
  RAILS_6_0_FIXED_DEPRECATION_WARNING_REGEXES = [
    /Dangerous query method \(method whose arguments are used as raw SQL\) called with non\-attribute argument\(s\)/,
    /The success\? predicate is deprecated and will be removed in Rails 6\.0/
  ].freeze

  # Regular expressions for Rails 6.1 deprecation warnings that we have addressed in the codebase
  RAILS_6_1_FIXED_DEPRECATION_WARNING_REGEXES = [
    /update_attributes is deprecated and will be removed from Rails 6\.1/
  ].freeze

  # Regular expressions for deprecation warnings that should raise an exception on detection
  DISALLOWED_DEPRECATION_WARNING_REGEXES = [
    *RAILS_6_0_FIXED_DEPRECATION_WARNING_REGEXES,
    *RAILS_6_1_FIXED_DEPRECATION_WARNING_REGEXES
  ].freeze

  # @param message [String] deprecation warning message to be checked against disallow list
  def raise_if_disallowed_deprecation!(message)
    if DISALLOWED_DEPRECATION_WARNING_REGEXES.any? { |re| re.match?(message) }
      fail DisallowedDeprecationError, message
    end
  end
end
