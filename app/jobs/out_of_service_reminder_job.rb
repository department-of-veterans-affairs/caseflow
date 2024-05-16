# frozen_string_literal: true

class OutOfServiceReminderJob < ApplicationJob
  queue_with_priority :low_priority

  def perform
    apps = %w[certification dispatch hearing_prep reader]
    out_of_service_apps = []

    out_of_service_apps.push("Caseflow") if Rails.cache.read("out_of_service")

    apps.each do |app|
      out_of_service_apps.push(app.humanize) if Rails.cache.read(app + "_out_of_service")
    end

    SlackService.new.send_notification(message(out_of_service_apps)) unless out_of_service_apps.empty?
  end

  def message(apps)
    if apps.include?("Caseflow")
      "Reminder: Caseflow has been taken out of service."
    else
      "Reminder: #{apps.to_sentence} are out of service."
    end
  end
end
