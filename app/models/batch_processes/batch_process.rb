# frozen_string_literal: true

class BatchProcess < CaseflowRecord
  self.inheritance_column = :batch_type
  has_many :priority_end_product_sync_queue, foreign_key: "batch_id", primary_key: "batch_id"
  has_many :end_product_establishments, through: :priority_end_product_sync_queue
  after_initialize :init_counters

  ERROR_LIMIT = ENV["MAX_ERRORS_BEFORE_STUCK"].to_i
  ERROR_DELAY = ENV["ERROR_DELAY"].to_i
  BATCH_LIMIT = ENV["BATCH_LIMIT"].to_i

  scope :completed_batch_process_ids, -> { where(state: Constants.BATCH_PROCESS.completed).select(:batch_id) }

  enum state: {
    Constants.BATCH_PROCESS.pre_processing.to_sym => Constants.BATCH_PROCESS.pre_processing,
    Constants.BATCH_PROCESS.processing.to_sym => Constants.BATCH_PROCESS.processing,
    Constants.BATCH_PROCESS.completed.to_sym => Constants.BATCH_PROCESS.completed

  }

  class << self
    def find_records
      # no-op, can be overwritten
    end

    def create_batch!(record)
      # no-op, can be overwritten
    end
  end

  def process_batch!
    # no-op, can be overwritten
  end

  private

  def init_counters
    @completed_count = 0
    @failed_count = 0
  end

  def batch_processing!
    update!(state: Constants.BATCH_PROCESS.processing, started_at: Time.zone.now)
  end

  def batch_complete!
    update!(state: Constants.BATCH_PROCESS.completed,
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
      record.declare_record_stuck!
    else
      record.status_error!(error_array)
    end

    Rails.logger.error(error.inspect)
  end
end
