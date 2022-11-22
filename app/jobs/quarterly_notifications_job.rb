# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  queue_as ApplicationController.dependencies_faked? ? :receive_notifications : :"receive_notifications.fifo"
  application_attr :hearing_schedule

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: None
  def perform

  end

  private

  # Purpose: Method to be called with an error need to be logged to the rails logger
  #
  # Params: error_message (Expecting a string) - Message to be logged to the logger
  #
  # Response: None
  def log_error(error_message)
    Rails.logger.error(error_message)
  end

end
