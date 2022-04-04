module GovDelivery::TMS #:nodoc:
  # A MessageType is a like a tag that can be attached to an EmailTemplate or an
  # EmailMessage. It is included in encoded links and can be used as a
  # Segmentation filter.
  #
  #
  # @attr code [String] The unique identifier of the MessageType.
  # @attr label [String] User facing description
  #
  class MessageType
    include InstanceResource

    # @!parse attr_reader :code, :label
    writeable_attributes :code, :label
  end
end
