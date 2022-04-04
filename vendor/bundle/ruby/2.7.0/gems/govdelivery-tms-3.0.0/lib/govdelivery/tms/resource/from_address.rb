module GovDelivery::TMS #:nodoc:
  # FromAddress is an email address, associated response addresses (reply to,
  # error to), and a display name that is used when sending an email via TMS.
  # All messages sent via TMS must have a FromAddress, which can be set via or
  # via a template. If neither is set with a message is sent, then the account's
  # default FromAddress will be used.
  #
  # This resource is read-only.
  #
  # To add more FromAddresses to your account, please contact your CSC.
  #
  # @attr from_email [String] Email address that a message will be sent from
  # @attr from_name [String] Display name of the sender of a message
  # @attr reploy_to_email [Stirng] Email address that will be used for the Reply-To header
  # @attr bounce_email [String] Email address that will be used for the Errors-To header
  # @attr is_default [Boolean] Indicates if the FromAddress is the account's default FromAddress
  class FromAddress
    include InstanceResource

    # @!parse attr_reader :id, :created_at
    readonly_attributes :id, :created_at, :from_email, :from_name, :reply_to_email, :bounce_email, :is_default
  end
end
