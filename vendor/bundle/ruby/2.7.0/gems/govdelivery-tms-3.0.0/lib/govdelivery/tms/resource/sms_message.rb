module GovDelivery::TMS #:nodoc:
  # An SMSMessage is used to create and send a text message to a collection of Recipient
  # objects.
  #
  #
  # @attr body [String] The content of the SMS.  This field will be truncated to 160 characters.
  #
  # @example
  #    sms = client.sms_messages.build(:body => "Hello")
  #    sms.recipients.build(:phone => "+18001002000")
  #    sms.post
  #    sms.get
  class SmsMessage
    include InstanceResource

    # @!parse attr_accessor :body
    writeable_attributes :body

    # @!parse attr_reader :id, :created_at, :completed_at, :status
    readonly_attributes :id, :created_at, :completed_at, :status

    ##
    # A CollectionResource of Recipient objects
    collection_attributes :recipients

    ##
    # A CollectionResource of Recipients that sent successfully
    collection_attribute :sent, 'Recipients'

    ##
    # A CollectionResource of Recipients that failed
    collection_attribute :failed, 'Recipients'

    linkable_attributes :sms_template
  end
end
