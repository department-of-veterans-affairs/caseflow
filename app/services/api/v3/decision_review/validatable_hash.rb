# frozen_string_literal: true

module Api::V3::DecisionReview::ValidatableHash
  OBJECT = [Hash, ActionController::Parameters, ActiveSupport::HashWithIndifferentAccess]
  BOOL = [true, false]
  NULLABLE_STRING = [String, nil]

  def type_error_for_key(keys_and_allowed_values)
    keys_and_allowed_values.find do |(key, values)|
      values = values.nil? ? [nil] : Array.wrap(values)
      break "#{self.hash_path_str}[\"#{key}\"] should be one of #{values}" if values.none? { |val| val === hash[key] }
    end
  end
end
