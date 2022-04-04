module GovDelivery::TMS #:nodoc:
  class EmailTemplate
    include InstanceResource

    # @!parse attr_accessor :body, :subject, :link_tracking_parameters, :macros, :open_tracking_enabled, :click_tracking_enabled
    writeable_attributes :body,
                         :subject,
                         :link_tracking_parameters,
                         :macros,
                         :message_type_code,
                         :open_tracking_enabled,
                         :click_tracking_enabled,
                         :uuid

    linkable_attributes :from_address, :message_type

    # @!parse attr_reader :id, :created_at
    readonly_attributes :id, :created_at

    collection_attribute :from_address, 'FromAddress'

    nullable_attributes :message_type_code
  end
end
