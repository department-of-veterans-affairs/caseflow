# frozen_string_literal: true

class ReceiveNotificationJob < CaseflowJob
  queue_as ApplicationController.dependencies_fakes? ? :receive_notifications : :"receive_notifications.fifo"
  def perform
    RequestStore.store[:current_user] = User.system_user
    queue_url = Shoryuken::Client.sqs.get_queue_url(queue_name: queue_name).queue_url
    receive_message_result = Shoryuken::Client.sqs.receive_message(
      queue_url: queue_url,
      message_attribute_names: ["All"],
      max_number_of_messages: 1,
      wait_time_seconds: 20,
      visibility_timeout: 5
    )
    message_list = receive_message_result.messages
    fail Caseflow::Error::EmptyQueueError, "There are no messages in queue yet" if message_list.empty?

    audit = send_to_database(receive_message_result)
    Shoryuken::Client.sqs.delete_message(queue_url: queue_url, receipt_handle: message_list.first.receipt_handle)
    Notification.create!(audit) unless audit["error"]
  end

  # send queued message to database store
  def sent_to_database(result)
    message = result.messages.first
    # check if current state has changed in database
    # if so, update and save record
    # remove queued message
  end
end
