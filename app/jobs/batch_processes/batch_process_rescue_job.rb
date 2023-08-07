# frozen_string_literal: true

# This job will search for and reprocess unfinished Batch Processes nightly.
# Search Criteria is for Batch Processes that are in an unfinished state ('PRE_PROCESSING', 'PROCESSING') &
# have a created_at date/time that is greater than the ERROR_DELAY defined within batch_process.rb
class BatchProcessRescueJob < CaseflowJob
  queue_with_priority :low_priority

  before_perform do |job|
    JOB_ATTR = job
  end

  def perform
    batches = BatchProcess.needs_reprocessing
    if batches.any?
      batches.each do |batch|
        begin
          batch.process_batch!
        rescue StandardError => error
          Rails.logger.error("Error: #{error.inspect}, Job ID: #{JOB_ATTR&.job_id}, Job Time: #{Time.zone.now}")
          capture_exception(error: error,
                            extra: { job_id: JOB_ATTR&.job_id.to_s,
                                     job_time: Time.zone.now.to_s })
          next
        end
      end
    else
      Rails.logger.info("No Unfinished Batches Could Be Identified.  Time: #{Time.zone.now}.")
    end
  end
end
