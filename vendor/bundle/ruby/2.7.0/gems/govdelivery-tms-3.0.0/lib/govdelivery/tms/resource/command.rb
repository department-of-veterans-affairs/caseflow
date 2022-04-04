module GovDelivery::TMS #:nodoc:
  # A command is a combination of behavior and parameters that should be executed
  # when an incoming SMS message matches the associated Keyword.
  #
  # @attr name [String] The name of the command.  This will default to the command_type if not supplied.
  # @attr command_type [String] The type of this command.  A list of valid types can be found by querying the CommandType list.
  # @attr params [Hash] A Hash of string/string pairs used as configuration for this command.
  #
  # @example
  #    command = keyword.commands.build(:name => "subscribe to news", :command_type => "dcm_subscribe", :dcm_account_code => "NEWS", :dcm_topic_codes => "NEWS_1, NEWS_2")
  #    command.post
  #    command.dcm_topic_codes += ", NEWS_5"
  #    command.put
  #    command.delete
  class Command
    include InstanceResource

    # @!parse attr_accessor :name, :command_type, :params
    writeable_attributes :name, :command_type, :params

    # @!parse attr_reader :created_at, :updated_at
    readonly_attributes :created_at, :updated_at
  end
end
