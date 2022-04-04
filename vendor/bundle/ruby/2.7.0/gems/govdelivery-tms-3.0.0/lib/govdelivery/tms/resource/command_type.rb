module GovDelivery::TMS #:nodoc:
  # CommandType is a pair of values (name, string_fields, array_fields) that can be attached
  # to a Keyword (in a Command object).
  #
  # This resource is read-only.
  #
  # @attr name [String] The name of the CommandType.
  # @attr string_fields [Array] An Array of strings representing the different string_fields on this
  #   CommandType.  Field values will always be strings.
  # @attr array_fields [Array] An array of strings representing the different array fields on this
  #   CommandType.  Field values will always be arrays of strings.
  #
  class CommandType
    include InstanceResource

    # @!parse attr_reader :string_fields, :array_fields, :name
    readonly_attributes :name, :string_fields, :array_fields
  end
end
