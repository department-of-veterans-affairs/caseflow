module GovDelivery::TMS #:nodoc:
  class SmsTemplate
    include InstanceResource

    # @!parse attr_accessor :body
    writeable_attributes :body, :uuid

    # @!parse attr_reader :id, :created_at
    readonly_attributes :id, :created_at

  end
end
