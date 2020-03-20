# frozen_string_literal: true

class VirtualHearings::DeleteConferencesJob < ApplicationJob
  include VirtualHearings::PexipClient

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    VirtualHearingRepository.ready_for_deletion.each do |virtual_hearing|
      Rails.logger.info("Deleting Pexip conference for hearing (#{virtual_hearing.hearing_id})")

      process_virtual_hearing(virtual_hearing)
    end

    VirtualHearingRepository.cancelled_hearings_with_pending_emails.each do |virtual_hearing|
      Rails.logger.info("Sending cancellation emails to recipients for hearing (#{virtual_hearing.hearing_id})")

      VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: :cancellation).call
    end
  end

  private

  def process_virtual_hearing(virtual_hearing)
    return unless delete_conference(virtual_hearing)

    virtual_hearing.update(conference_deleted: true)

    if virtual_hearing.cancelled?
      Rails.logger.info("Sending cancellation emails to recipients for hearing (#{virtual_hearing.hearing_id})")

      VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: :cancellation).call
    end
  end

  # Returns whether or not the conference was deleted from Pexip
  def delete_conference(virtual_hearing)
    response = client.delete_conference(conference_id: virtual_hearing.conference_id)

    fail response.error unless response.success?

    true
  rescue Caseflow::Error::PexipNotFoundError
    Rails.logger.info("Pexip response: #{response}")
    Rails.logger.info("Conference for hearing (#{virtual_hearing.hearing_id}) was already deleted" )

    # Assume the conference was already deleted if it's no longer in Pexip.
    true
  rescue Caseflow::Error::PexipApiError => error
    Rails.logger.info("Pexip response: #{response}")
    Rails.logger.error("Failed to delete conference from Pexip with error: (#{error.code}) #{error.message}")

    capture_exception(
      error: error,
      extra: {
        hearing_id: virtual_hearing.hearing_id,
        virtual_hearing_id: virtual_hearing.id,
        pexip_conference_Id: virtual_hearing.conference_id
      }
    )

    false
  end
end
