module GovDelivery::TMS #:nodoc:
  # An EmailRecipient is used in conjunction with an EmailMessage to send email.
  #
  # @attr email [String] The recipient email address
  # @attr macros [Hash] A dictionary of key/value pairs to resolve in the subject and body as macros. This value can be nil.
  #
  # @example Sending a message
  #    email_message = client.email_messages.build(:subject => "Great news!", :body => "You win! <a href='http://example.com/'>click here</a>.")
  #    email_message.recipients.build(:email => "john@example.com")
  #    email_message.recipients.build(:email => "jeff@example.com")
  #    email_message.post
  #    email_message.get
  #
  class EmailRecipient
    include InstanceResource

    # @!parse attr_accessor :email, :macros
    writeable_attributes :email, :macros

    # @!parse attr_reader :completed_at, :status, :error_message
    readonly_attributes :completed_at, :status, :error_message

    ##
    # A CollectionResource of EmailRecipientOpens for this EmailRecipient
    readonly_collection_attribute :opens, 'EmailRecipientOpens'

    ##
    # A CollectionResource of EmailRecipientClicks for this EmailRecipient
    readonly_collection_attribute :clicks, 'EmailRecipientClicks'
  end
end
