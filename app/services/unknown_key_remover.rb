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
      schema
        .fields
        .select { |field| field.nested? && params.include?(field.name) }
        .each do |field|
          remover = UnknownKeyRemover.new(field.nested)
          if field.is_a?(ControllerSchema::ArrayField)
            params[field.name].map { |value| remover.remove_unknown_keys_in_place(value) }
          else
            remover.remove_unknown_keys_in_place(params[field.name])
          end
        end
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
      schema
        .fields
        .select { |field| field.nested? && params.include?(field.name) }
        .each do |field|
          remover = UnknownKeyRemover.new(field.nested)
          params[field.name] = if field.is_a?(ControllerSchema::ArrayField)
                                 params[field.name].map { |value| remover.remove_unknown_keys(value) }
                               else
                                 remover.remove_unknown_keys(params[field.name])
                               end
        end
    end

    params
  end

  private

  attr_reader :schema

  # Wrapper around an implementation to remove unknown keys.
  #
  # @param params      [ActionController::Parameters] parameters from the body of a request
  # @param path_params [Hash] parameters that form the path of a request
  def remove_unknown_keys_wrapper(params, path_params)
    allowed = allowed_keys(path_params)
    removed = remove_keys(params, path_params)

    yield(allowed)
    Rails.logger.info("Removed unknown keys from controller params: #{removed}") if removed.present?
  end

  # Determines which keys are allowed by the schema.
  #
  # @param path_params [Hash] parameters that form the path of a request
  #
  # @return            [Array<String>]
  #   A list of keys that are allowed by the schema
  def allowed_keys(path_params)
    (schema.fields.map(&:name) + path_params.keys).map(&:to_s)
  end

  # Determines which keys to remove from the parameters of a request.
  #
  # @param params      [ActionController::Parameters] parameters from the body of a request
  # @param path_params [Hash] parameters that form the path of a request
  #
  # @return            [Array<String>]
  #   A list of keys to remove
  def remove_keys(params, path_params)
    params.keys - allowed_keys(path_params)
  end
end
