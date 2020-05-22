# frozen_string_literal: true

# shared code for controllers that perform schema validation

module ValidationConcern
  extend ActiveSupport::Concern

  included do
    before_action :validate_schema
  end

  class_methods do
    def validates(action_name, using:)
      validation_schemas[action_name.to_sym] = using
    end

    def validation_schemas
      @validation_schemas ||= {}
    end
  end

  def validate_schema
    schema = self.class.validation_schemas[action_name.to_sym]
    return if schema.nil?

    result = schema.call(params.to_unsafe_h)
    if result.failure?
      errors = result.errors.map { |msg| msg.path.join(".") + " #{msg.text}" }
      respond_to do |format|
        format.text { render plain: errors.join("; "), status: :unprocessable_entity }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end
end
