module GovDelivery::TMS #:nodoc:
  class EmailRecipientOpen
    include InstanceResource

    # @!parse attr_reader :event_at
    readonly_attributes :event_at
  end
end
