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

  # Returns only the params specified in the schema.
  def permitted_params
    schema = self.class.validation_schemas[action_name.to_sym]
    return if schema.nil?

    UnknownKeyRemover.new(schema).remove_unknown_keys(params).permit!
  end

  # :nocov:
  def validate_schema
    schema = self.class.validation_schemas[action_name.to_sym]
    return if schema.nil?

    UnknownKeyRemover.new(schema).remove_unknown_keys_in_place(params, path_params: request.path_parameters)
    result = schema.validate(params)
    if result.failure?
      errors = result.errors.map { |msg| msg.path.join(".") + " #{msg.text}" }
      respond_to do |format|
        format.text { render plain: errors.join("; "), status: :unprocessable_entity }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end
  # :nocov:
end
