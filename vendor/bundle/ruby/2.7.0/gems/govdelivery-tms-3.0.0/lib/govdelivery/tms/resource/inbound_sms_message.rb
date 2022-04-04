module GovDelivery::TMS #:nodoc:
  class InboundSmsMessage
    include InstanceResource

    # @!parse attr_reader :created_at, :completed_at, :from, :body, :to, :command_status
    readonly_attributes :created_at, :completed_at, :from, :body, :to, :command_status, :keyword_response
  end
end
