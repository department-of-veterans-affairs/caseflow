module GovDelivery::TMS #:nodoc:
  class EmailRecipientClick
    include InstanceResource

    # @!parse attr_reader :event_at, :url
    readonly_attributes :event_at, :url
  end
end
