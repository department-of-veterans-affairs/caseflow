# frozen_string_literal: true

# Class used by create_payload_method in AppellantNotification module to create message
class VANotifySendMessageTemplate
  # Constructs Object with attributes that are sent to VA Notify
  # Appeal ID is UUID for AMA Appeals and Vacols ID for Legacy Appeals
  # message_attributes is a hash containing strings of participant_id, appeal_id, appeal_type, status,
  # & appeal_status (only used for quarterly notifications)
  attr_reader :participant_id, :template_name, :appeal_id, :appeal_type, :status, :appeal_status
  def initialize(message_attributes, template_name, appeal_status = nil)
    @participant_id = message_attributes[:participant_id]
    @template_name = template_name
    @appeal_id = message_attributes[:appeal_id]
    @appeal_type = message_attributes[:appeal_type]
    @status = message_attributes[:status]
    @appeal_status = appeal_status
  end
end
