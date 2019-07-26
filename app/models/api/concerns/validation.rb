# frozen_string_literal: true

module Api::Validation
  extend ActiveSupport::Concern
  include Api::Helpers

  private 

  def is_int?(value, key: nil, exception: ArgumentError)
    return true if value == to_int(value)
    raise exception, join_present(key, "isn't an int : <#{value}>") if exception
    false
  end

  def is_int_or_int_string?(value, key: nil, exception: ArgumentError)
    return true if is_int?(value, exception: nil) || to_int(value)
    message = "is neither an int nor a string that can be converted to an int: <#{value}>"
    raise exception, join_present(key, message) if exception
    false
  end

  def is_present?(value, key: nil, exception: ArgumentError)
    return true if value.present?
    raise exception, join_present(key, "is blank: <#{value.inspect}>") if exception
    false
  end

  def is_nullable_array?(value, key: nil, exception: ArgumentError)
    return true if value.nil? || value.is_a?(Array)
    raise exception, join_present(key, "is neither an array nor nil: <#{value}>") if exception
    false
  end

  def is_string?(value, key: nil, exception: ArgumentError)
    return true if value.is_a?(String)
    raise exception, join_present(key, "is not a string: <#{value}>") if exception
    false
  end

  def is_nullable_string?(value, key: nil, exception: ArgumentError)
    return true if value.nil? || value.is_a?(String)
    raise exception, join_present(key, "is neither a string nor nil: <#{value}>") if exception
    false
  end

  # date string: "YYYY-MM-DD"
  def is_date_string?(value, key: nil, exception: ArgumentError)
    return true if Date.valid_date?(*(value.split("-").map { |s| to_int s }))
    raise exception, join_present(key, "is not a date string: <#{value}>") if exception
    false
  end

  # date string: "YYYY-MM-DD"
  def is_nullable_date_string?(value, key: nil, exception: ArgumentError)
    return true if value.nil? || is_date_string?(value, exception: nil)
    raise exception, join_present(key, "is neither a date string nor nil: <#{value}>") if exception
    false
  end

  def is_boolean?(value, key: nil, exception: ArgumentError)
    return true value.is_a?(TrueClass) || value.is_a?(FalseClass)
    raise exception, join_present(key, "is not a boolean: <#{value}>") if exception
    false
  end

  def is_true?(value, key: nil, exception: ArgumentError)
    return true value == true
    raise exception, join_present(key, "is not true: <#{value}>") if exception
    false
  end

  def is_null_or_benefit_type?(value, key: nil, exception: ArgumentError)
    return true if value.nil? || Api::HigherLevelReviewPreintake::BENEFIT_TYPES[value]
    raise exception, join_present(key, "is not a benefit type (line of business): <#{value}>") if exception
    false
  end

  def is_null_or_nonrating_issue_category_for_benefit_type?(category, benefit_type, exception: ArgumentError)
    return true if category.nil? || category.in?(
                     Api::HigherLevelReviewPreintake::NONRATING_ISSUE_CATEGORIES[benefit_type] || [])
    raise exception, "<#{category}> is not a valid category for benefit_type: <#{benefit_type}>") if exception
    false
  end

  def any_present?(*values, keys:, exception: ArgumentError) # keys required
    return true if values.any?(&:present?)
    raise exception, "at least one must be present: #{keys}" if exception
    false
  end

  private def extra_keys(hash, expected_keys:)
    hash.except(*expected_keys).keys
  end

  def hash_keys_are_within_this_set?(hash, keys:, exception: ArgumentError) # keys required
    extras = extra_keys hash, expected_keys: keys
    return true if extras.empty?
    raise exception, "hash has extra keys: #{extras}" if exception
    false
  end

  private def missing_keys(hash, expected_keys:)
    expected_keys.filter?{|k| !hash.has_key? k}
  end

  def hash_has_at_least_these_keys?(hash, keys:, exception: ArgumentError) # keys required
    missing = missing_keys hash, expected_keys: keys
    return true if missing.empty?
    raise exception, "hash is missing keys: #{missing}" if exception
    false
  end

  def these_are_the_hash_keys?(hash, keys:, exception: ArgumentError) # keys required
    extras = extra_keys hash, expected_keys: keys
    missing = missing_keys hash, expected_keys: keys
    return true if extras.empty? && missing.empty?
    message = join_present(
      extras.present? && "hash has extra keys: #{extras}",
      missing.present? && "hash is missing keys: #{missing}"
    )
    raise exception, message if exception
    false
  end
end
