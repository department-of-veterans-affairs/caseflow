# frozen_string_literal: true

class VirtualHearings::DeleteConferencesJob < VirtualHearings::ConferenceJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    VirtualHearingRepository.cancelled_hearings_with_pending_emails.each do |virtual_hearing|
      Rails.logger.info("Sending cancellation emails to recipients for hearing (#{virtual_hearing.hearing_id})")

      send_cancellation_emails(virtual_hearing)
    end

    count_deleted_and_log(VirtualHearingRepository.ready_for_deletion) do |virtual_hearing|
      Rails.logger.info("Deleting Pexip conference for hearing (#{virtual_hearing.hearing_id})")

      process_virtual_hearing(virtual_hearing)
    end
  end

  private

  def send_cancellation_emails(virtual_hearing)
    VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: :cancellation).call
  end

  def count_deleted_and_log(enumerable)
    failed = removed = 0

    enumerable.each do |virtual_hearing|
      if yield(virtual_hearing)
        removed += 1
      else
        failed += 1
      end
    end

    if removed > 0
      DataDogService.increment_counter(
        metric_name: "deleted_conferences.successful", by: removed, **datadog_metric_info
      )
    end

    if failed > 0
      DataDogService.increment_counter(
        metric_name: "deleted_conferences.failed", by: failed, **datadog_metric_info
      )
    end
  end

  def process_virtual_hearing(virtual_hearing)
    deleted_conference = delete_conference(virtual_hearing)

    return false unless deleted_conference

    virtual_hearing.update(conference_deleted: true)

    true
  end

  # Returns whether or not the conference was deleted from Pexip
  def delete_conference(virtual_hearing)
    response = client.delete_conference(conference_id: virtual_hearing.conference_id)

    fail response.error unless response.success?

    true
  rescue Caseflow::Error::PexipNotFoundError
    Rails.logger.info("Pexip response: #{response}")
    Rails.logger.info("Conference for hearing (#{virtual_hearing.hearing_id}) was already deleted")

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
