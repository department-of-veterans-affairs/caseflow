module GovDelivery::TMS #:nodoc:
  # A Keyword is a word that TMS will detect in an incoming SMS message.  Keywords can have Commands, and
  # when an incoming text message has a keyword, TMS will execute the keyword's Commands.  Keywords may
  # also have a response text field.  If the response text is not blank, the system will send an SMS reply to the user
  # immediately with the given text.
  #
  # @attr name [String] The name of the keyword.  The system will scan an incoming SMS for this string (in a case-insensitive manner).
  # @attr response_text [String] (Optional) The static text with which to reply to an SMS to this keyword.
  #   This value can be blank, in which case the handset user will not receive a response.
  #   Note that all keyword commands will be executed, regardless of the value of response_text.
  #
  # @example
  #   keyword = client.keywords.build(:name => "HOWDY")
  #   keyword.post
  #   keyword.name = "INFO"
  #   keyword.response_text = "Please call our support staff at 1-555-555-5555"
  #   keyword.put
  #   keyword.delete
  class Keyword
    include InstanceResource

    # @!parse attr_accessor :name, :response_text
    writeable_attributes :name, :response_text

    ##
    # A CollectionResource of Command objects
    collection_attributes :commands
  end
end
