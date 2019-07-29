# frozen_string_literal: true

module Api::V3::Concerns::Validation
  extend ActiveSupport::Concern
  include Api::V3::Concerns::Helpers

  DEFAULT_ERROR = Api::V3::MalformedRequestError

  private

  def present?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.present?

    fail exception, join_present(name_of_value, "is blank: <#{value.inspect}>") if exception

    false
  end

  def any_present?(*values, names_of_values: nil, exception: DEFAULT_ERROR)
    return true if values.any?(&:present?)

    names_of_values &&= ": #{names_of_values}"
    fail exception, "at least one must be present#{names_of_values}" if exception

    false
  end

  def hash?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.is_a?(Hash)

    fail exception, join_present(name_of_value, "isn't a hash: <#{value}>") if exception

    false
  end

  def array?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.is_a?(Array)

    fail exception, join_present(name_of_value, "is not an array: <#{value}>") if exception

    false
  end

  def nullable_array?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.nil? || array?(value, exception: nil)

    fail exception, join_present(name_of_value, "is neither an array nor nil: <#{value}>") if exception

    false
  end

  # date string: "YYYY-MM-DD"
  def date_string?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if begin
      Date.valid_date?(*(value.split("-").map { |s| to_int s }))
                   rescue StandardError # if the splitting raises an exception
                     false
    end

    fail exception, join_present(name_of_value, "is not a date string: <#{value}>") if exception

    false
  end

  def nullable_date_string?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.nil? || date_string?(value, exception: nil)

    fail exception, join_present(name_of_value, "is neither a date string nor nil: <#{value}>") if exception

    false
  end

  def benefit_type?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.in? Api::V3::HigherLevelReviewPreintake::BENEFIT_TYPES

    fail exception, join_present(name_of_value, "is not a benefit type (line of business): <#{value}>") if exception

    false
  end

  def nullable_benefit_type?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.nil? || benefit_type?(value, exception: nil)

    fail exception, join_present(name_of_value, "is neither a benefit type (line of business) nor nil: <#{value}>") if exception

    false
  end

  def nonrating_issue_category_for_benefit_type?(category, benefit_type, names_of_values: %w[category benefit_type], exception: DEFAULT_ERROR)
    return false unless benefit_type?(benefit_type, name_of_value: names_of_values.is_a?(Array) && names_of_values[1], exception: exception)

    categories = Api::V3::HigherLevelReviewPreintake::NONRATING_ISSUE_CATEGORIES[benefit_type]
    return true if category.in? categories

    names_of_values = if names_of_values.is_a?(Array) && names_of_values.length == 2
                        "for #{names_of_values[0]} and #{names_of_values[1]},"
                      end

    if exception
      fail exception, join_present(
        names_of_values,
        "either <#{category}> is not a valid category for benefit type <#{benefit_type}>,",
        "or <#{benefit_type}> isn't a valid benefit type."
      )
    end

    false
  end

  def nullable_nonrating_issue_category_for_benefit_type?(category, benefit_type, names_of_values: %w[category benefit_type], exception: DEFAULT_ERROR)
    return true if category.nil? || nonrating_issue_category_for_benefit_type?(category, benefit_type, exception: nil)

    names_of_values = if names_of_values.is_a?(Array) && names_of_values.length == 2
                        "for #{names_of_values[0]} and #{names_of_values[1]},"
                      end

    name_of_category_variable = if names_of_values.is_a?(Array) && names_of_values[0].present?
                                  names_of_values[0]
                                else
                                  "category specified"
                                end

    if exception
      fail exception, join_present(
        names_of_values,
        "either #{name_of_category_variable} isn't nil,",
        "or <#{category}> isn't a valid category for benefit type <#{benefit_type}>,",
        "or <#{benefit_type}> isn't a valid benefit type."
      )
    end

    false
  end

  def payee_code?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.in? Api::V3::RequestIssuePreintake::PAYEE_CODES

    fail exception, join_present(name_of_value, "is not a valid payee code: <#{value}>") if exception

    false
  end

  def hash_keys_are_within_this_set?(hash, keys:, name_of_value: nil, exception: DEFAULT_ERROR)
    extras = extra_keys hash, expected_keys: keys

    return true if extras.empty?

    fail exception, join_present("hash", name_of_value, "has extra keys: #{extras}") if exception

    false
  end

  def hash_has_at_least_these_keys?(hash, keys:, name_of_value: nil, exception: DEFAULT_ERROR)
    missing = missing_keys hash, expected_keys: keys

    return true if missing.empty?

    fail exception, join_present("hash", name_of_value, "is missing keys: #{missing}") if exception

    false
  end

  def these_are_the_hash_keys?(hash, keys:, name_of_value: nil, exception: DEFAULT_ERROR)
    extras = extra_keys hash, expected_keys: keys
    missing = missing_keys hash, expected_keys: keys

    return true if extras.empty? && missing.empty?

    message = join_present(
      extras.present? && join_present("hash", name_of_value, "has extra keys: #{extras}"),
      missing.present? && join_present("hash", name_of_value, "is missing keys: #{missing}")
    )
    fail(exception, message) if exception

    false
  end
end
