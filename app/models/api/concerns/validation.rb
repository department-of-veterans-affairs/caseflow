# frozen_string_literal: true

module Api::Validation
  extend ActiveSupport::Concern
  include Api::Helpers

  private 

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

  def is_benefit_type?(value, key: nil, exception: ArgumentError)
    return true if Api::HigherLevelReviewPreintake::BENEFIT_TYPES[value]
    raise exception, join_present(key, "is not a benefit type (line of business): <#{value}>") if exception
    false
  end

  def is_nonrating_issue_category?(value, key: nil, exception: ArgumentError)
    return true if Api::HigherLevelReviewPreintake::NONRATING_ISSUE_CATEGORIES[value]
    raise exception, join_present(key, "is not a nonrating issue category: <#{value}>") if exception
    false
  end

  def any_present?(*values, keys:, exception: ArgumentError) # keys required
    return true if values.any?(&:present?)
    raise exception, "at least one must be present: #{keys}" if exception
  end
end
