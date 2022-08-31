# frozen_string_literal: true

# Class used by AppellantNotification module to create JSON payload as a Ruby Object
class VANotifySendMessageTemplate
  # Constructs message that is sent to VA Notify
  def initialize(info, template_name, queue_url = "caseflow_development_send_notifications")
    @queue_url = queue_url
    @message_body = "Notification for #{info[:appeal_type]}, #{template_name}"
    @message_attributes = {
      "participant_id": {
        string_value: info[:participant_id], data_type: "String"
      },
      "template_name": {
        string_value: template_name, data_type: "String"
      },
      "appeal_id": {
        string_value: info[:appeal_id], data_type: "String"
      },
      "appeal_type": {
        string_value: info[:appeal_type], data_type: "String"
      },
      "status": {
        string_value: info[:status], data_type: "String"
      }
    }
  end

  attr_reader :queue_url, :message_body, :message_attributes

  # Instance Methods used to get attributes of message
  def participant_id
    @message_attributes[:participant_id][:string_value]
  end

  def template_name
    @message_attributes[:template_name][:string_value]
  end

  def appeal_id
    @message_attributes[:appeal_id][:string_value]
  end

  def appeal_type
    @message_attributes[:appeal_type][:string_value]
  end

  def status
    @message_attributes[:status][:string_value]
  end
end
