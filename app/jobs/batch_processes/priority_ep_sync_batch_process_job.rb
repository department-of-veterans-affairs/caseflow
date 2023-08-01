# frozen_string_literal: true

class PriorityEpSyncBatchProcessJob < CaseflowJob
  queue_with_priority :low_priority

  # Using macro-style definition. The locking scope will be TheClass#method and only one method can run at any given time.
  include RedisMutex::Macro

  # Default options for RedisMutex#with_lock
  # :block  => 1    # Specify in seconds how long you want to wait for the lock to be released.
  #                 # Specify 0 if you need non-blocking sematics and return false immediately. (default: 1)
  # :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
  #                 # It is NOT recommended to go below 0.01. (default: 0.1)
  # :expire => 10   # Specify in seconds when the lock should be considered stale when something went wrong
  #                 # with the one who held the lock and failed to unlock. (default: 10)

  JOB_DURATION = 1.hour
  SLEEP_DURATION = 60.seconds

  before_perform do |job|
    JOB_ATTR = job
  end

  # Attempts to create & process batches for an hour
  # There will be a 1 minute rest between each iteration
  def perform
    setup_job
    loop do
      break if job_running_past_expected_end_time?

      begin
        RedisMutex.with_lock("PriorityEpSyncBatchProcessJob", block: 30, expire: 60) do # key => "PriorityEpSyncBatchProcessJob"
          @batch = ActiveRecord::Base.transaction do
            records_to_batch = PriorityEpSyncBatchProcess.find_records_to_batch
            next if records_to_batch.empty?

            PriorityEpSyncBatchProcess.create_batch!(records_to_batch)
          end
        end

        if @batch
          @batch.process_batch!
        else
          Rails.logger.info("No Records Available to Batch.  Job ID: #{JOB_ATTR&.job_id}.  Time: #{Time.zone.now}")
        end
      rescue StandardError => error
        Rails.logger.error("Error: #{error.inspect}, Job ID: #{JOB_ATTR&.job_id}, Job Time: #{Time.zone.now}")
        capture_exception(error: error,
                          extra: { job_id: JOB_ATTR&.job_id.to_s,
                                  job_time: Time.zone.now.to_s })
      end

      sleep(SLEEP_DURATION)
    end
  end

  private

  attr_accessor :job_expected_end_time

  def setup_job
    RequestStore.store[:current_user] = User.system_user

    @job_expected_end_time = Time.zone.now + JOB_DURATION
  end

  def job_running_past_expected_end_time?
    Time.zone.now > job_expected_end_time
  end
end
