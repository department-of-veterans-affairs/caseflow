# frozen_string_literal: true

class ReceiveNotificationJob < ApplicationJob
  # Pulls messages that are received from the message queue
  def pull; end

  # Update the notifications audit record from the content of the message
  def update; end

  # Delete message from queue
  def delete; end

  # Run job
  def run; end
end
