# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# A job that pulls messages from the 'receive_notifications' FIFO SQS queue
# that represent status updates for VA Notify notifications and persists
# the information in our notifications table.
#
# The messages are queued by {Api::V1::VaNotifyController#notifications_update} which is
# an endpoint where VA Notify sends information to us about notifications we've requested
# that they send via their
# {https://github.com/department-of-veterans-affairs/notification-api/blob/1b758dddf2d2c12d73415e4ee508cf6b0e101343/app/celery/service_callback_tasks.py#L29 send_delivery_status_to_service} callback.
#
# This information includes:
# - The latest status pertaining to the notification's delivery (ex: success or temporary-failure)
# - The status reason (extra context around the status, if available)
# - The recipient's email or phone number
#   - Caseflow simply provides VA Notify with the intended recipient's participant ID with each initial notification request, and it does not know of the destination of a message until they inform us.
#
# @see https://github.com/department-of-veterans-affairs/caseflow/wiki/VA-Notify
# @see https://github.com/department-of-veterans-affairs/caseflow/wiki/Status-Webhook-API
# rubocop:enable Layout/LineLength
class ProcessNotificationStatusUpdatesJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority

  MESSAGE_GROUP_ID = "VANotifyStatusUpdate" # Used to only process messages queued by the status update webhook
  PROCESSING_LIMIT = 5000 # How many updates to perform per job execution

  # Consumes messages from the 'receive_notifications' FIFO SQS queue whose 'MessageGroupId'
  # attribute matches MESSAGE_GROUP_ID, and then persists data contained within those messages
  # about VA Notify notifications to our 'notifications' table.
  def perform
    ensure_current_user_is_set

    begin
      number_of_messages_processed = 0

      number_of_messages_processed += process_batch_of_messages while number_of_messages_processed < PROCESSING_LIMIT
    rescue Caseflow::Error::SqsQueueExhaustionError
      Rails.logger.info("ProcessNotificationStatusUpdatesJob is exiting early due to the queue being empty.")
    rescue StandardError => error
      log_error(error)
      raise error
    ensure
      Rails.logger.info("#{number_of_messages_processed} messages have been processed by this execution.")
    end
  end

  private

  # Returns the SQS URL of the 'receive_notifications' FIFO SQS queue for the
  #  current environment using a substring.
  #
  # @return [String]
  #   The URL of the queue that messages will be pulled from.
  def recv_queue_url
    @recv_queue_url ||= SqsService.find_queue_url_by_name(name: "receive_notifications", check_fifo: true)
  end

  # Pulls in up to 10 messages from the 'receive_notifications' FIFO SQS queue
  #  and consume the data in order to persist VA Notify status updates to the
  #  the notifications table.
  #
  # @see https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/controllers/api/v1/va_notify_controller.rb
  #
  # @return [Integer]
  #   The number of messages that were attempted to be processed in a batch.
  def process_batch_of_messages
    response = SqsService.sqs_client.receive_message(
      {
        queue_url: recv_queue_url,
        max_number_of_messages: 10,
        attribute_names: ["MessageGroupId"]
      }
    )

    # Exit loop early if there does not seem to be any more messages.
    fail Caseflow::Error::SqsQueueExhaustionError if response.messages.empty?

    filtered_messages = filter_messages_by_group_id(response.messages)

    batch_status_updates(filtered_messages)
    SqsService.batch_delete_messages(queue_url: recv_queue_url, messages: filtered_messages)

    # Return the number of messages attempted to be processed
    filtered_messages.size
  end

  # Sorts pending status update messages by notification type and performs up to two
  #  separate UPDATE queries to persist data to the corresponding notifications
  #  table records.
  #
  # @param messages [Array<Aws::SQS::Types::Message>] A collection of AWS SQS messages.
  #
  # @return [Boolean]
  #   True/False depending on if the final totals could be logged.
  def batch_status_updates(messages)
    parsed_bodies = messages.map { |msg| JSON.parse(msg.body) }

    email_rows_update_count = update_email_statuses(filter_body_by_notification_type(parsed_bodies, "email"))
    sms_rows_update_count = update_sms_statuses(filter_body_by_notification_type(parsed_bodies, "sms"))

    Rails.logger.info(
      "Email statuses updated: #{email_rows_update_count} - SMS statuses updated: #{sms_rows_update_count}"
    )
  end

  # Filters messages bodies by notification_type.
  #
  # @param bodies [Array<Hash<String, String>>] A collection of the bodies of messages that have been
  #  parsed into hashes.
  # @param notification_type [String] The type of notification to filter for. 'email' and 'sms'
  #  are the two valid types at the time of writing this comment.
  #
  # @return [Array<Hash<String, String>>]
  #   Messages bodies whose notification_type matches the desired one.
  def filter_body_by_notification_type(bodies, notification_type)
    bodies.filter { _1["notification_type"] == notification_type }
  end

  # Performs updates to any email notifications in the current batch of messages
  #  being processed. Statuses, status reasons, and recipient informations are items that are updated.
  #
  # @param status_update_list [Array<Hash<String, String>>] A collection of the bodies of messages that have been
  #  parsed into hashes. These represent VA Notify status updates.
  #
  # @return [Integer]
  #   The number of rows that have been updated.
  def update_email_statuses(status_update_list)
    return 0 if status_update_list.empty?

    query = <<-SQL
      UPDATE notifications AS n SET
        email_notification_status = new.n_status,
        recipient_email = new.recipient,
        email_status_reason = new.status_reason
      FROM ( VALUES
        #{build_values_mapping(status_update_list)}
      ) AS new(external_id, n_status, status_reason, recipient)
       WHERE new.external_id = n.email_notification_external_id
    SQL

    ActiveRecord::Base.connection.update(query)
  end

  # Performs updates to any SMS notifications in the current batch of messages
  #  being processed. Statuses, status reasons, and recipient informations are items that are updated.
  #
  # @param status_update_list [Array<Hash<String, String>>] A collection of the bodies of messages that have been
  #  parsed into hashes. These represent VA Notify status updates.
  #
  # @return [Integer]
  #   The number of rows that have been updated.
  def update_sms_statuses(status_update_list)
    return 0 if status_update_list.empty?

    query = <<-SQL
      UPDATE notifications AS n SET
        sms_notification_status = new.n_status,
        recipient_phone_number = new.recipient,
        sms_status_reason = new.status_reason
      FROM ( VALUES
        #{build_values_mapping(status_update_list)}
      ) AS new(external_id, n_status, status_reason, recipient)
       WHERE new.external_id = n.sms_notification_external_id
    SQL

    ActiveRecord::Base.connection.update(query)
  end

  # Builds a comma-delimited list of VALUES expressions to represent the data to be used
  #  in updated notification statuses, status reasons, and recipient information.
  #
  # @param status_update_list [Array<Hash<String, String>>] A collection of the bodies of messages that have been
  #  parsed into hashes. These represent VA Notify status updates.
  #
  # @return [String]
  #   A sanitized SQL string consisting of VALUE expressions.
  def build_values_mapping(status_update_list)
    values = status_update_list.map do |status_update|
      external_id = status_update["external_id"]
      status = status_update["status"]
      status_reason = status_update["status_reason"]
      recipient = status_update["recipient"]

      "('#{external_id}', '#{status}', '#{status_reason}', '#{recipient}')"
    end

    ActiveRecord::Base.sanitize_sql(values.join(","))
  end

  # Filters out SQS messages whose MessageGroupId isn't the one utilized by our VA Notify webhooks
  #  so that they're not accidentally processed.
  #
  # @param messages [Array<Aws::SQS::Types::Message>] A collection of messages to be filtered.
  #
  # @return [Array<Aws::SQS::Types::Message>]
  #   Messages whose MessageGroupId matches the one this job expect. Messages with
  #   a different MessageGroupId will be ignored.
  def filter_messages_by_group_id(messages)
    messages.filter { _1.attributes["MessageGroupId"] == MESSAGE_GROUP_ID }
  end
end
