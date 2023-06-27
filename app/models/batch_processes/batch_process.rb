# frozen_string_literal: true

class BatchProcess < CaseflowRecord
  self.inheritance_column = :batch_type
  has_many :priority_end_product_sync_queue, foreign_key: "batch_id", primary_key: "batch_id"
  after_initialize :init_counters

  ERROR_LIMIT = ENV["MAX_ERRORS_BEFORE_STUCK"].to_i
  ERROR_DELAY = ENV["ERROR_DELAY"].to_i
  BATCH_LIMIT = ENV["BATCH_LIMIT"].to_i

  class << self
    def find_records_to_batch
      # no-op, can be overwritten
    end

    def create_batch!
      # no-op, can be overwritten
    end
  end

  def build_batch!(records_to_batch)
    # no-op, can be overwritten
  end

  def process_batch!
    # no-op, can be overwritten
  end

  private

  def init_counters
    @completed_count = 0
    @failed_count = 0
    @attempted_count = 0
  end

  def records_attempted!
    update!(records_attempted: @attempted_count)
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
    else
      record.unbatch!(error_array)
    end
    Rails.logger.error(error.inspect)
  end

  def declare_record_stuck!(record)
    record.stuck!
  end
end
