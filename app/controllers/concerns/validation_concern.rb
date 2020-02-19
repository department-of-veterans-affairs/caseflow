# frozen_string_literal: true

# shared code for controllers that perform schema validation.

module ValidationConcern
  extend ActiveSupport::Concern

  included do
    before_action :validate_schema
  end

  def validate_schema
    # Approach 1 for associating schema with controller action
    schema = try("#{action_name}_schema")
    return if schema.nil?

    result = schema.call(params.to_unsafe_h)
    if result.failure?
      error = result.errors.map { |msg| msg.path.join(".") + " #{msg.text}" }.join("; ")
      raise StandardError.new(error)
    end
  end
end
