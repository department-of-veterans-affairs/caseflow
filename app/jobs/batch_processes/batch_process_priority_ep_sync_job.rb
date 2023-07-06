# frozen_string_literal: true

class BatchProcessPriorityEpSyncJob < CaseflowJob
  queue_with_priority :low_priority

  before_perform do |job|
    JOB_ATTR = job
  end

  def perform
    begin
      batch = ActiveRecord::Base.transaction do
        records_to_batch = BatchProcessPriorityEpSync.find_records
        next if records_to_batch.empty?

        BatchProcessPriorityEpSync.create_batch!(records_to_batch)
      end

      if batch
        batch.process_batch!
      else
        Rails.logger.info("No Records Available to Batch.  Time: #{Time.zone.now}")
      end
    rescue StandardError => error
      Rails.logger.error("Error: #{error.inspect}, Job ID: #{JOB_ATTR&.job_id}, Job Time: #{Time.zone.now}")
      capture_exception(error: error,
                        extra: { job_id: JOB_ATTR&.job_id.to_s,
                                 job_time: Time.zone.now.to_s })
    end
  end
end
