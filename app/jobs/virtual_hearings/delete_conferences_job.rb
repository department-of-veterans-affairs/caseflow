# frozen_string_literal: true

class DeleteConferencesJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    puts "Hyello"
  end

  private

  def delete_conference(conference)

  rescue

  end
end
