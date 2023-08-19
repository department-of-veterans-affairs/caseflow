# frozen_string_literal: true

class PriorityEpSyncBatchProcessJob < CaseflowJob
  queue_with_priority :low_priority

  # Using macro-style definition. The locking scope will be TheClass#method and only one method can run at any
  # given time.
  include RedisMutex::Macro

  # Default options for RedisMutex#with_lock
  # :block  => 1    # Specify in seconds how long you want to wait for the lock to be released.
  #                 # Specify 0 if you need non-blocking sematics and return false immediately. (default: 1)
  # :sleep  => 0.1  # Specify in seconds how long the polling interval should be when :block is given.
  #                 # It is NOT recommended to go below 0.01. (default: 0.1)
  # :expire => 10   # Specify in seconds when the lock should be considered stale when something went wrong
  #                 # with the one who held the lock and failed to unlock. (default: 10)
  #
  # RedisMutex.with_lock("PriorityEpSyncBatchProcessJob", block: 60, expire: 100)
  # Key => "PriorityEpSyncBatchProcessJob"

  JOB_DURATION ||= ENV["BATCH_PROCESS_JOB_DURATION"].to_i.minutes
  SLEEP_DURATION ||= ENV["BATCH_PROCESS_SLEEP_DURATION"].to_i

  # Attempts to create & process batches for 50 minutes
  # There will be a 5 second rest between each iteration
  # Job will end if there are no records are left to batch

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
  def perform
    setup_job
    loop do
      break if job_running_past_expected_end_time? || should_stop_job

      begin
        batch = nil
        RedisMutex.with_lock("PriorityEpSyncBatchProcessJob", block: 60, expire: 100) do
          batch = ActiveRecord::Base.transaction do
            records_to_batch = PriorityEpSyncBatchProcess.find_records_to_batch
            next if records_to_batch.empty?

            PriorityEpSyncBatchProcess.create_batch!(records_to_batch)
          end
        end

        batch ? batch.process_batch! : stop_job(log_no_records_found: true)

        sleep(SLEEP_DURATION)
      rescue StandardError => error
        log_error(error, extra: { job_id: job_id.to_s, job_time: Time.zone.now.to_s })
        slack_msg = "Error running #{self.class.name}.  Error: #{error.message}.  Active Job ID: #{job_id}."
        slack_msg += "  See Sentry event #{Raven.last_event_id}." if Raven.last_event_id.present?
        slack_service.send_notification("[ERROR] #{slack_msg}", self.class.to_s)
        stop_job
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

  private

  attr_accessor :job_expected_end_time, :should_stop_job

  def setup_job
    RequestStore.store[:current_user] = User.system_user
    @should_stop_job = false
    @job_expected_end_time = Time.zone.now + JOB_DURATION
  end

  def job_running_past_expected_end_time?
    Time.zone.now > job_expected_end_time
  end

  def stop_job(log_no_records_found: false)
    self.should_stop_job = true
    if log_no_records_found
      Rails.logger.info("#{self.class} Cannot Find Any Records to Batch."\
        "  Job will be enqueued again at the top of the hour.  Active Job ID: #{job_id}.  Time: #{Time.zone.now}")
    end
  end
end
