# frozen_string_literal: true

class VirtualHearings::SendReminderEmailsJob < ApplicationJob
  include VirtualHearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    ensure_current_user_is_set

    VirtualHearingRepository.maybe_ready_for_reminder_email.each do |virtual_hearing|
      begin
        send_reminder_emails(virtual_hearing)
      rescue StandardError => error # rescue any error and allow job to continue
        capture_exception(error: error)
      end
    end
  end

  private

  def send_reminder_emails(virtual_hearing)
    if should_send_appellant_reminder?(virtual_hearing)
      VirtualHearings::SendEmail
        .new(virtual_hearing: virtual_hearing, type: :appellant_reminder)
        .call
    end

    if virtual_hearing.representative_email.present? && should_sent_representative_reminder?(virtual_hearing)
      VirtualHearings::SendEmail
        .new(virtual_hearing: virtual_hearing, type: :representative_reminder)
        .call
    end
  end

  def should_send_appellant_reminder?(virtual_hearing)
    VirtualHearings::ReminderService
      .new(virtual_hearing, virtual_hearing.appellant_reminder_sent_at)
      .should_send_reminder_email?
  end

  def should_sent_representative_reminder?(virtual_hearing)
    VirtualHearings::ReminderService
      .new(virtual_hearing, virtual_hearing.representative_reminder_sent_at)
      .should_send_reminder_email?
  end
end
