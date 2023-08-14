# frozen_string_literal: true

# This job will find deltas between the end product establishment table and the VBMS ext claim table
# where VBMS ext claim level status code is CLR or CAN. If EP is already in the queue it will be skipped.
# Job will populate queue ENV["END_PRODUCT_QUEUE_BATCH_LIMIT"] records at a time.
# This job will run on a 1-hr loop, sleeping for 5 seconds between iterations.
class PopulateEndProductSyncQueueJob < CaseflowJob
  queue_with_priority :low_priority

  JOB_DURATION ||= ENV["END_PRODUCT_QUEUE_JOB_DURATION"].to_i.hour
  SLEEP_DURATION ||= ENV["END_PRODUCT_QUEUE_SLEEP_DURATION"].to_i
  BATCH_LIMIT ||= ENV["END_PRODUCT_QUEUE_BATCH_LIMIT"].to_i

  before_perform do |job|
    JOB_ATTR = job
  end

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
        Rails.logger.error("Error: #{error.inspect}, Job ID: #{JOB_ATTR&.job_id}, Job Time: #{Time.zone.now}")
        capture_exception(error: error,
                          extra: { job_id: JOB_ATTR&.job_id.to_s,
                                   job_time: Time.zone.now.to_s })
        stop_job
      end
    end
  end

  private

  attr_accessor :job_expected_end_time, :should_stop_job

  def find_priority_end_product_establishments_to_sync
    get_batch = <<-SQL
    select id
      from end_product_establishments
      inner join vbms_ext_claim
      on end_product_establishments.reference_id = vbms_ext_claim."CLAIM_ID"::varchar
      where (end_product_establishments.synced_status <> vbms_ext_claim."LEVEL_STATUS_CODE" or end_product_establishments.synced_status is null)
        and vbms_ext_claim."LEVEL_STATUS_CODE" in ('CLR','CAN')
        and end_product_establishments.id not in (select end_product_establishment_id from priority_end_product_sync_queue)
      limit #{BATCH_LIMIT};
    SQL

    ActiveRecord::Base.connection.exec_query(ActiveRecord::Base.sanitize_sql(get_batch)).rows.flatten
  end

  def insert_into_priority_sync_queue(batch)
    batch.each do |ep_id|
      PriorityEndProductSyncQueue.create!(
        end_product_establishment_id: ep_id
      )
    end
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

  def stop_job(log_no_records_found: false)
    self.should_stop_job = true
    if log_no_records_found
      Rails.logger.info("PopulateEndProductSyncQueueJob is not able to find any batchable EPE records."\
        "  Job ID: #{JOB_ATTR&.job_id}.  Time: #{Time.zone.now}")
    end
  end
end
