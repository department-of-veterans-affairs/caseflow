# frozen_string_literal: true

class BatchProcess < CaseflowRecord
  has_many :priority_end_product_sync_queue, foreign_key: "batch_id"
  after_initialize :init_counters

  ERROR_LIMIT = ENV["MAX_ERRORS_BEFORE_STUCK"].to_i
  ERROR_DELAY = ENV["ERROR_DELAY"].to_i
  BATCH_LIMIT = ENV["BATCH_LIMIT"].to_i

  class << self
    def find_records_to_batch
      PriorityEndProductSyncQueue.where("batch_id IS NULL AND (last_batched_at IS NULL OR last_batched_at <= ?)",
                                        ERROR_DELAY.hours.ago).lock.limit(BATCH_LIMIT)
    end

    def create_batch!
      uuid = SecureRandom.uuid
      BatchProcess.create!(batch_id: uuid, batch_type: "priority_end_product_sync")
    end

    def build_priority_end_product_sync_batch!(records_to_batch)
      batch = BatchProcess.create_batch!
      batch.batch_priority_queued_epes!(records_to_batch)
      batch.records_attempted!
      batch
    end
  end

  def process_priority_end_product_sync!
    process_state!
    priority_end_product_sync_queue.each do |record|
      epe = record.end_product_establishment
      begin
        epe.sync!

        fail Caseflow::Error::PriorityEndProductSyncError, "Claim Not In VBMS_EXT_CLAIM." unless epe.vbms_ext_claim
        if epe.synced_status != epe.vbms_ext_claim&.level_status_code
          fail Caseflow::Error::PriorityEndProductSyncError, "EPE synced_status does not match VBMS."
        end
      rescue StandardError => error
        error_out_record!(record, error)
        next
      end
      record.finished_sync_status!
      increment_completed
    end
    complete_state!
  end

  def batch_priority_queued_epes!(records_to_batch)
    @attempted_count = records_to_batch.count
    records_to_batch.update_all(batch_id: batch_id,
                                status: "PRE_PROCESSING",
                                last_batched_at: Time.zone.now)
  end

  def records_attempted!
    update!(records_attempted: @attempted_count)
  end

  private

  def init_counters
    @completed_count = 0
    @failed_count = 0
    @attempted_count = 0
  end

  def process_state!
    update!(state: "PROCESSING", started_at: Time.zone.now)
  end

  def complete_state!
    update!(state: "COMPLETED",
            records_failed: @failed_count,
            records_completed: @completed_count,
            ended_at: Time.zone.now)
  end

  def increment_completed
    @completed_count += 1
  end

  def increment_failed
    @failed_count += 1
  end

  def error_out_record!(record, error)
    increment_failed
    error_array = record.error_messages || []
    error_array.push("Error: #{error.inspect} - Batch ID: #{record.batch_id} - Time: #{Time.zone.now}.")
    if error_array.length >= ERROR_LIMIT
      declare_record_stuck!(record)
    end
    record.unbatch!(error_array)
    Rails.logger.error(error.inspect)
  end

  def declare_record_stuck!(record)
    record.stuck!
  end
end
