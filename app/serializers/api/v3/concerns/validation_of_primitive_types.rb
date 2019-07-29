# frozen_string_literal: true

module Api::V3::Concerns::Validation
  extend ActiveSupport::Concern
  include Api::V3::Concerns::Helpers

  private

  def hash?(value, name_of_value: nil, exception: ArgumentError)
    value.is_a?(Hash) || (exception ? fail(exception, join_present(name_of_value, "isn't a hash: <#{value}>")) : false)
  end

  def int?(value, name_of_value: nil, exception: ArgumentError)
    return true if !value.nil? && value == to_int(value)

    fail(exception, join_present(name_of_value, "isn't an int: <#{value}>")) if exception

    false
  end

  def int_greater_than_zero?(value, name_of_value: nil, exception: ArgumentError)
    raise_exception_with_message = ->{fail exception, join_present(name_of_value, "isn't an int greater than zero: <#{value}>")}
    unless int? value, exception: nil
      raise_exception_with_message[] if exception
      return false
    end
    return true if to_int(value) > 0
    raise_exception_with_message[] if exception
    false 
  end

  def int_or_int_string?(value, name_of_value: nil, exception: ArgumentError)
    return true if int?(value, exception: nil) || (to_int(value) && to_int(value) == to_float(value))

    message = "is neither an int nor a string that can be converted to an int: <#{value}>"
    exception ? fail(exception, join_present(name_of_value, message)) : false
  end

  def present?(value, name_of_value: nil, exception: ArgumentError)
    value.present? || (exception ? fail(exception, join_present(name_of_value, "is blank: <#{value.inspect}>")) : false)
  end

  def array?(value, name_of_value: nil, exception: ArgumentError)
    value.is_a?(Array) || (exception ? fail(exception, join_present(name_of_value, "is not an array: <#{value}>")) : false)
  end

  def nullable_array?(value, name_of_value: nil, exception: ArgumentError)
    value.nil? || array?(value, name_of_value: name_of_value, exception: exception)
  end

  def string?(value, name_of_value: nil, exception: ArgumentError)
    value.is_a?(String) || (
      exception ? fail(exception, join_present(name_of_value, "is not a string: <#{value}>")) : false
    )
  end

  def nullable_string?(value, name_of_value: nil, exception: ArgumentError)
    value.nil? || string?(value, name_of_value: name_of_value, exception: exception)
  end

  # date string: "YYYY-MM-DD"
  def date_string?(value, name_of_value: nil, exception: ArgumentError)
    return true if begin
      Date.valid_date?(*(value.split("-").map { |s| to_int s }))
                   rescue StandardError # if the splitting raises an exception
                     false
    end

    fail exception, join_present(name_of_value, "is not a date string: <#{value}>") if exception

    false
  end

  def nullable_date_string?(value, name_of_value: nil, exception: ArgumentError)
    value.nil? || date_string?(value, name_of_value: name_of_value, exception: exception)
  end

  def boolean?(value, name_of_value: nil, exception: ArgumentError)
    return true if value.is_a?(TrueClass) || value.is_a?(FalseClass)
    fail exception, join_present(name_of_value, "is not a boolean: <#{value}>") if exception

    false
  end

  def true?(value, name_of_value: nil, exception: ArgumentError)
    (value == true) || (exception ? fail(exception, join_present(name_of_value, "is not true: <#{value}>")) : false)
  end

  def benefit_type?(value, name_of_value: nil, exception: ArgumentError)
    return true if value.in? Api::V3::HigherLevelReviewPreintake::BENEFIT_TYPES
    fail exception, join_present(name_of_value, "is not a benefit type (line of business): <#{value}>") if exception

    false
  end

  def nullable_benefit_type?(value, name_of_value: nil, exception: ArgumentError)
    value.nil? || benefit_type?(value, name_of_value: name_of_value, exception: exception)
  end

  def nonrating_issue_category_for_benefit_type?(category, benefit_type, exception: ArgumentError)
    return false unless benefit_type?(benefit_type, exception: exception)

    categories = Api::V3::HigherLevelReviewPreintake::NONRATING_ISSUE_CATEGORIES[benefit_type]
    return true if category.in? categories
    fail exception, "<#{category}> is not a valid category for benefit_type: <#{benefit_type}>" if exception

    false
  end

  def nullable_nonrating_issue_category_for_benefit_type?(category, benefit_type, exception: ArgumentError)
    category.nil? || nonrating_issue_category_for_benefit_type?(
      category, benefit_type, exception: exception
    )
  end

  def payee_code?(value, name_of_value: nil, exception: ArgumentError)
    return true if value.in? Api::V3::RequestIssuePreintake::PAYEE_CODES
    fail exception, join_present(name_of_value, "is not a valid payee code: <#{value}>") if exception

    false
  end

  def any_present?(*values, names_of_values: nil, exception: ArgumentError)
    values.any?(&:present?) || (exception ? fail(exception, "at least one must be present: #{names_of_values}") : false)
  end

  def hash_keys_are_within_this_set?(hash, keys:, name_of_value: nil, exception: ArgumentError)
    extras = extra_keys hash, expected_keys: keys
    return true if extras.empty?
    fail exception, join_present("hash", name_of_value, "has extra keys: #{extras}") if exception

    false
  end

  def hash_has_at_least_these_keys?(hash, keys:, name_of_value: nil, exception: ArgumentError)
    missing = missing_keys hash, expected_keys: keys
    return true if missing.empty?
    fail exception, join_present("hash", name_of_value, "is missing keys: #{missing}") if exception

    false
  end

  def these_are_the_hash_keys?(hash, keys:, name_of_value: nil, exception: ArgumentError)
    extras = extra_keys hash, expected_keys: keys
    missing = missing_keys hash, expected_keys: keys
    return true if extras.empty? && missing.empty?

    message = join_present(
      extras.present? && join_present("hash", name_of_value, "has extra keys: #{extras}"),
      missing.present? && join_present("hash", name_of_value, "is missing keys: #{missing}")
    )
    exception ? fail(exception, message) : false
  end
end
