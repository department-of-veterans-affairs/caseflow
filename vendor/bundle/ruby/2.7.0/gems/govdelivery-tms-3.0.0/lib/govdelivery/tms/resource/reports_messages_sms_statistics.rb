module GovDelivery::TMS #:nodoc:
  class ReportsMessagesSmsStatistics
    include InstanceResource

    # @!parse attr_reader :recipients
    readonly_attributes :recipients
  end
end
