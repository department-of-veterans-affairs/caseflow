# frozen_string_literal: true

class BatchProcessPriorityEPSyncJob < CaseflowJob
  queue_with_priority :low_priority

  before_perform do |job|
    JOB_ATTR = job
  end

  def perform
    begin
      batch = ActiveRecord::Base.transaction do
        records_to_batch = BatchProcess.find_records_to_batch
        next unless records_to_batch.any?

        BatchProcess.build_priority_end_product_sync_batch!(records_to_batch)
      end
      if batch
        batch.process_priority_end_product_sync!
      else
        Rails.logger.info("No Records Available to Batch.  Time: #{Time.zone.now}")
      end
    rescue StandardError => error
      Rails.logger.error("Error: #{error.inspect}, Job ID: #{JOB_ATTR&.job_id}, Job Time: #{Time.zone.now}")
      capture_exception(error: error, extra: { job_id: JOB_ATTR&.job_id.to_s, job_time: Time.zone.now.to_s })
    end
  end
end
