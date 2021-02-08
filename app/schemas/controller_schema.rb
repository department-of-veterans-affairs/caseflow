# frozen_string_literal: true

class ControllerSchema
  SUPPORTED_TYPES = %w[bool date datetime integer nested string].freeze

  class Field
    attr_reader :name, :type, :optional, :nullable, :included_in, :doc

    def initialize(name, type, **options)
      @name = name
      @type = type
      @optional = options.fetch(:optional, false)
      @nullable = options.fetch(:nullable, false)
      @included_in = options.fetch(:included_in?, nil)&.map do |value|
        value.is_a?(Symbol) ? value.to_s : value
      end
      @doc = options.fetch(:doc, nil)
    end

    # convert this Field into a DSL entry on a Dry::Schema
    def register(dry_dsl)
      dsl_type = (type == :nested) ? :hash : type # hash is a reserved built-in name
      key = register_key(dry_dsl)
      if nullable
        key = key.maybe(dsl_type)
        key.value(**value_options) if value_options.present?
      else
        key.value(dsl_type, **value_options)
      end
    end

    private

    def register_key(dry_dsl)
      dry_dsl.send((optional ? "optional" : "required"), name)
    end

    def value_options
      return {} if included_in.nil?

      if nullable
        { "included_in?": included_in + [nil] }
      else
        { "included_in?": included_in }
      end
    end
  end

  class << self
    def params(&block)
      ControllerSchema.new("Params", &block)
    end

    def json(&block)
      ControllerSchema.new("JSON", &block)
    end
  end

  attr_reader :format, :fields

  def initialize(format, &block)
    @format = format
    @fields = []
    instance_eval(&block) if block
  end

  # mutates params by removing fields not declared in the schema, other than path params
  def remove_unknown_keys(params, path_params = {})
    allowed = (fields.map(&:name) + path_params.keys).map(&:to_s)
    removed = params.keys - allowed
    params.slice!(*allowed)
    Rails.logger.info("Removed unknown keys from controller params: #{removed}") if removed.present?
  end

  def validate(params)
    dry_schema.call(params.to_unsafe_h)
  end

  def dry_schema
    @dry_schema ||= begin
      dsl = Dry::Schema::DSL.new(processor_type: dry_processor)
      @fields.each { |field| field.register(dsl) }
      dsl.call
    end
  end

  private

  def method_missing(method_name, field_name, **options)
    if SUPPORTED_TYPES.include?(method_name.to_s)
      @fields << Field.new(field_name, method_name, **options)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    SUPPORTED_TYPES.include?(method_name.to_s) || super
  end

  def dry_processor
    "Dry::Schema::#{format}".constantize
  end
end
