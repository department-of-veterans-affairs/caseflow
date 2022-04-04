module GovDelivery::TMS #:nodoc:
  class Recipient
    include InstanceResource
    # @!parse attr_accessor :phone
    writeable_attributes :phone

    # @!parse attr_reader :formatted_phone, :error_message, :status, :completed_at
    readonly_attributes :formatted_phone, :error_message, :status, :completed_at
  end
end
