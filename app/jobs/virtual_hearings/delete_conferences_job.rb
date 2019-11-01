# frozen_string_literal: true

class VirtualHearings::DeleteConferencesJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    VirtualHearingRepository.ready_for_deletion.map do |virtual_hearing|
      delete_conference(virtual_hearing)

      send_cancellation_emails if virtual_hearing.cancelled?

      virtual_hearing.save!
    end
  end

  private

  def pexip_service
    @service ||= PexipService.new(
      host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
      port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
      user_name: ENV["PEXIP_USERNAME"],
      password: ENV["PEXIP_PASSWORD"],
      client_host: ENV["PEXIP_CLIENT_HOST"]
    )
  end

  def delete_conference(virtual_hearing)
    pexip_service.delete_conference(conference_id: virtual_hearing.conference_id)
  rescue PexipNotFoundError
    # Assume the conference was already deleted if it's no longer in Pexip.
    virtual_hearing.conference_deleted = true
  rescue PexipApiError => error
    Rails.logger.error("Failed to delete conference from Pexip with error: #{error}")

    capture_exception(
      error: error,
      extra: {
        hearing_id: virtual_hearing.hearing_id,
        virtual_hearing_id: virtual_hearing.id,
        pexip_conference_Id: virtual_hearing.conference_id
      }
    )
  end

  def send_cancellation_emails(virtual_hearing)
    if !virtual_hearing.veteran_email_sent
      # TODO: Send the email
      virtual_hearing.veteran_email_sent = true
    end

    if !virtual_hearing.judge_email_sent
      # TODO: Send the email
      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email.nil? && !virtual_hearing.representative_email_sent
      # TODO: Send the email
      virtual_hearing.representative_email_sent = true
    end
  end
end
