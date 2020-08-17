# frozen_string_literal: true

# Removes unknown keys from a value based on a controller schema
class UnknownKeyRemover
  def initialize(schema)
    @schema = schema
  end

  # Mutates params by removing fields not declared in the schema, other than path params (in place)
  #
  # @param params      [ActionController::Parameters] parameters from the body of a request
  # @param path_params [Hash] parameters that form the path of a request
  def remove_unknown_keys_in_place(params, path_params: {})
    remove_unknown_keys_wrapper(params, path_params) do |allowed|
      params.slice!(*allowed)

      # Recursively descend into nested params and remove unknown keys.
      nested_schema_fields(params).each { |field| handle_nested_field_in_place(field, params) }
    end
  end

  # Mutates params by removing fields not declared in the schema, other than path params
  #
  # @param params      [ActionController::Parameters] parameters from the body of a request
  # @param path_params [Hash] parameters that form the path of a request
  #
  # @return            [ActionController::Parameters]
  #   Request parameters with unknown keys removed
  def remove_unknown_keys(params, path_params: {})
    remove_unknown_keys_wrapper(params, path_params) do |allowed|
      params = params.slice(*allowed)

      # Recursively descend into nested params and remove unknown keys.
      nested_schema_fields(params).each { |field| handle_nested_field(field, params) }
    end

    params
  end

  private

  attr_reader :schema

  # Removes unknown keys for a nested schema field.
  #
  # @param field       [ControllerSchema::Field] the nested schema field
  # @param params      [ActionController::Parameters] parameters from the body of a request
  def handle_nested_field(field, params)
    remover = UnknownKeyRemover.new(field.nested)
    params[field.name] = if field.is_a?(ControllerSchema::ArrayField)
                           params[field.name].map { |value| remover.remove_unknown_keys(value) }
                         else
                           remover.remove_unknown_keys(params[field.name])
                         end
  end

  # Removes unknown keys for a nested schema field (in place).
  #
  # @param field       [ControllerSchema::Field] the nested schema field
  # @param params      [ActionController::Parameters] parameters from the body of a request
  def handle_nested_field_in_place(field, params)
    remover = UnknownKeyRemover.new(field.nested)
    if field.is_a?(ControllerSchema::ArrayField)
      params[field.name].map { |value| remover.remove_unknown_keys_in_place(value) }
    else
      remover.remove_unknown_keys_in_place(params[field.name])
    end
  end

  # Wrapper around an implementation to remove unknown keys.
  #
  # @param params      [ActionController::Parameters] parameters from the body of a request
  # @param path_params [Hash] parameters that form the path of a request
  def remove_unknown_keys_wrapper(params, path_params)
    allowed = (schema.fields.map(&:name) + path_params.keys).map(&:to_s)
    removed = params.keys - allowed

    yield(allowed)
    Rails.logger.info("Removed unknown keys from controller params: #{removed}") if removed.present?
  end

  # Gets a list of nested schema fields that are present in the request parameters.
  #
  # @param params      [ActionController::Parameters] parameters from the body of a request
  #
  # @return            [Array<ControllerSchema::Field>]
  #   A list of nested schema fields
  def nested_schema_fields(params)
    schema
      .fields
      .select { |field| field.nested? && params.include?(field.name) }
  end
end
