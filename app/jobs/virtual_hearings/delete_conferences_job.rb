# frozen_string_literal: true

##
# Job that deletes the pexip conference resource if the hearing was held or
# if the hearing type is switched from virtual to original hearing type.
# It also sends cancellation emails to hearing participants if latter is case.

class VirtualHearings::DeleteConferencesJob < VirtualHearings::ConferenceJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  class DeleteConferencesJobFailure < StandardError; end

  # error for when emails fail to send
  class EmailsFailedToSend < StandardError; end

  before_perform do
    Rails.logger.info(
      "#{self.class.name} for deleting Pexip conferences and sending cancellation emails"
    )
  end

  retry_on(DeleteConferencesJobFailure, attempts: 5, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    extra = {
      application: job.class.app_name.to_s
    }

    Raven.capture_exception(exception: exception, extra: extra)
  end

  def perform(email_type: :convert_from_virtual_confirmation)
    ensure_current_user_is_set
    @exception_list = {} # reset on every perform

    VirtualHearingRepository.cancelled_with_pending_emails.each do |virtual_hearing|
      log_virtual_hearing_state(virtual_hearing)

      Rails.logger.info("Sending cancellation emails to recipients for hearing (#{virtual_hearing.hearing_id})")

      send_cancellation_emails(virtual_hearing, email_type)
    end

    count_deleted_and_log(VirtualHearingRepository.ready_for_deletion) do |virtual_hearing|
      log_virtual_hearing_state(virtual_hearing)

      Rails.logger.info("Deleting Pexip conference for hearing (#{virtual_hearing.hearing_id})")

      process_virtual_hearing(virtual_hearing)
    end

    log_failed_virtual_hearings if exception_list.present?

    # raise DeleteConferencesJobFailure if EmailsFailedToSend and/or PexipApiErrors were raised
    fail DeleteConferencesJobFailure if exception_list.present?
  end

  private

  def exception_list
    @exception_list ||= {}
  end

  def log_failed_virtual_hearings
    vh_with_pexip_errors = exception_list[Caseflow::Error::PexipApiError]
    if vh_with_pexip_errors
      Rails.logger.info("Failed to delete conferences for the following hearings: " \
        "#{vh_with_pexip_errors.map(&:hearing_id)}")
    end

    vh_with_email_errors = exception_list[EmailsFailedToSend]
    if vh_with_email_errors
      Rails.logger.info("Failed to send emails for the following hearings: " \
        "#{vh_with_email_errors.map(&:hearing_id)}")
    end
  end

  def log_virtual_hearing_state(virtual_hearing)
    super

    Rails.logger.info("Cancelled?: (#{virtual_hearing.cancelled?})")
    Rails.logger.info("Pexip conference id: (#{virtual_hearing.conference_id?})")
  end

  def send_cancellation_emails(virtual_hearing, email_type)
    return if virtual_hearing.hearing.postponed_or_cancelled_or_scheduled_in_error?

    Hearings::SendEmail.new(virtual_hearing: virtual_hearing, type: email_type).call

    if !virtual_hearing.cancellation_emails_sent?
      fail EmailsFailedToSend # failing so we can log errors
    end
  rescue EmailsFailedToSend => error
    Rails.logger.info("Failed to send all emails for hearing (#{virtual_hearing.hearing_id})")
    (exception_list[EmailsFailedToSend] ||= []) << virtual_hearing # add the virtual hearing to the exception list

    extra = {
      hearing_id: virtual_hearing.hearing_id,
      virtual_hearing_id: virtual_hearing.id
    }
    capture_exception(error: error, extra: extra)
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
    Rails.logger.info("Pexip response: #{response}")

    fail response.error unless response.success?

    true
  rescue Caseflow::Error::PexipNotFoundError
    Rails.logger.info("Conference for hearing (#{virtual_hearing.hearing_id}) was already deleted")

    # Assume the conference was already deleted if it's no longer in Pexip.
    true
  rescue Caseflow::Error::PexipApiError => error
    Rails.logger.error("Failed to delete conference from Pexip for hearing (#{virtual_hearing.hearing_id})" \
      " with error: (#{error.code}) #{error.message}")

    # add the virtual hearing to the exception list
    (exception_list[Caseflow::Error::PexipApiError] ||= []) << virtual_hearing

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
