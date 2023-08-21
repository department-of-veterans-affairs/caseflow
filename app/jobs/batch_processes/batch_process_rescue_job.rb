# frozen_string_literal: true

# This job will search for and reprocess unfinished Batch Processes nightly.
# Search Criteria is for Batch Processes that are in an unfinished state ('PRE_PROCESSING', 'PROCESSING') &
# have a created_at date/time that is greater than the ERROR_DELAY defined within batch_process.rb
class BatchProcessRescueJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    batches = BatchProcess.needs_reprocessing
    if batches.any?
      batches.each do |batch|
        begin
          batch.process_batch!
        rescue StandardError => error
          log_error(error, extra: { active_job_id: job_id.to_s, job_time: Time.zone.now.to_s })
          slack_msg = "Error running #{self.class.name}.  Error: #{error.message}.  Active Job ID: #{job_id}."
          slack_msg += "  See Sentry event #{Raven.last_event_id}." if Raven.last_event_id.present?
          slack_service.send_notification("[ERROR] #{slack_msg}", self.class.to_s)
          next
        end
      end
    else
      Rails.logger.info("No Unfinished Batches Could Be Identified.  Time: #{Time.zone.now}.")
    end
  end
end
