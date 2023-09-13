# frozen_string_literal: true

# This job will find deltas between the end product establishment table and the VBMS ext claim table
# where VBMS ext claim level status code is CLR or CAN. If EP is already in the queue it will be skipped.
# Job will populate queue ENV["END_PRODUCT_QUEUE_BATCH_LIMIT"] records at a time.
# This job will run on a 50 minute loop, sleeping for 5 seconds between iterations.
class PopulateEndProductSyncQueueJob < CaseflowJob
  queue_with_priority :low_priority

  JOB_DURATION ||= ENV["END_PRODUCT_QUEUE_JOB_DURATION"].to_i.minutes
  SLEEP_DURATION ||= ENV["END_PRODUCT_QUEUE_SLEEP_DURATION"].to_i
  BATCH_LIMIT ||= ENV["END_PRODUCT_QUEUE_BATCH_LIMIT"].to_i

  # rubocop:disable Metrics/CyclomaticComplexity
  def perform
    setup_job
    loop do
      break if job_running_past_expected_end_time? || should_stop_job

      begin
        batch = ActiveRecord::Base.transaction do
          priority_epes = find_priority_end_product_establishments_to_sync
          next if priority_epes.empty?

          priority_epes
        end

        batch ? insert_into_priority_sync_queue(batch) : stop_job(log_no_records_found: true)

        sleep(SLEEP_DURATION)
      rescue StandardError => error
        log_error(error, extra: { active_job_id: job_id.to_s, job_time: Time.zone.now.to_s })
        slack_msg = "Error running #{self.class.name}.  Error: #{error.message}.  Active Job ID: #{job_id}."
        slack_msg += "  See Sentry event #{Raven.last_event_id}." if Raven.last_event_id.present?
        slack_service.send_notification("[ERROR] #{slack_msg}", self.class.to_s)
        stop_job
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  attr_accessor :job_expected_end_time, :should_stop_job

  # rubocop:disable Metrics/MethodLength
  def find_priority_end_product_establishments_to_sync
    get_sql = <<-SQL
      WITH priority_eps AS (
        SELECT vec."CLAIM_ID"::varchar, vec."LEVEL_STATUS_CODE"
        FROM vbms_ext_claim vec
        WHERE vec."LEVEL_STATUS_CODE" in ('CLR', 'CAN')
          AND (vec."EP_CODE" LIKE '04%' OR vec."EP_CODE" LIKE '03%' OR vec."EP_CODE" LIKE '93%' OR vec."EP_CODE" LIKE '68%')
      ),
      priority_queued_epe_ids AS (
        SELECT end_product_establishment_id
        FROM priority_end_product_sync_queue)
      SELECT id
      FROM end_product_establishments epe
      INNER JOIN priority_eps
      ON epe.reference_id = priority_eps."CLAIM_ID"
      WHERE (epe.synced_status is null or epe.synced_status <> priority_eps."LEVEL_STATUS_CODE")
        AND NOT EXISTS (SELECT end_product_establishment_id
                        FROM priority_queued_epe_ids
                        WHERE priority_queued_epe_ids.end_product_establishment_id = epe.id)
      LIMIT #{BATCH_LIMIT};
    SQL

    ActiveRecord::Base.connection.exec_query(ActiveRecord::Base.sanitize_sql(get_sql)).rows.flatten
  end
  # rubocop:enable Metrics/MethodLength

  def insert_into_priority_sync_queue(batch)
    priority_end_product_sync_queue_records = batch.map do |ep_id|
      PriorityEndProductSyncQueue.new(end_product_establishment_id: ep_id)
    end

    # Bulk insert PriorityEndProductSyncQueue records in a single SQL statement
    PriorityEndProductSyncQueue.import(priority_end_product_sync_queue_records)
    Rails.logger.info("PopulateEndProductSyncQueueJob EPEs processed: #{batch} - Time: #{Time.zone.now}")
  end

  def setup_job
    RequestStore.store[:current_user] = User.system_user
    @should_stop_job = false
    @job_expected_end_time = Time.zone.now + JOB_DURATION
  end

  def job_running_past_expected_end_time?
    Time.zone.now > job_expected_end_time
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  def stop_job(log_no_records_found: false)
    self.should_stop_job = true
    if log_no_records_found
      Rails.logger.info("PopulateEndProductSyncQueueJob is not able to find any batchable EPE records."\
        "  Active Job ID: #{job_id}.  Time: #{Time.zone.now}")
    end
  end
end
