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

  def hash_keys_are_within_this_set?(hash, keys:, name_of_value: nil, exception: ArgumentError)
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
