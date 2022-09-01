# frozen_string_literal: true

# Class used by create_payload_method in AppellantNotification module to create message
class VANotifySendMessageTemplate
  # Constructs message that is sent to VA Notify
  # Appeal ID is UUID for AMA Appeals and Vacols ID for Legacy Appeals
  attr_reader :participant_id, :template_name, :appeal_id, :appeal_type, :status
  def initialize(info, template_name)
    @participant_id = info[:participant_id]
    @template_name = template_name
    @appeal_id = info[:appeal_id]
    @appeal_type = info[:appeal_type]
    @status = info[:status]
  end
end
