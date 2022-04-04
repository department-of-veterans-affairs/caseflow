module GovDelivery::TMS #:nodoc:
  class ReportsMessagesEmailStatistics
    include InstanceResource

    # @!parse attr_reader :recipients
    readonly_attributes :recipients
  end
end
