# frozen_string_literal: true

class ControllerSchema
  SUPPORTED_TYPES = %w[bool date datetime integer string].freeze

  class Field
    attr_reader :name, :type, :optional, :nullable, :included_in, :doc

    def initialize(name, type, **options)
      @name = name
      @type = type
      @optional = options.fetch(:optional, false)
      @nullable = options.fetch(:nullable, false)
      @included_in = options.fetch(:included_in?, nil)
      @doc = options.fetch(:doc, nil)
    end

    # convert this Field into a DSL entry on a Dry::Schema
    def register(dry_dsl)
      key = dry_dsl.send((optional ? "optional" : "required"), name)
      value_opts = included_in.nil? ? {} : { "included_in?": included_in }
      if nullable
        key = key.maybe(type)
        key.value(**value_opts) if value_opts.present?
      else
        key.value(type, **value_opts)
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
