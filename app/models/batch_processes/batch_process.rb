# frozen_string_literal: true

class BatchProcess < CaseflowRecord
  self.inheritance_column = :batch_type
  has_many :priority_end_product_sync_queue, foreign_key: "batch_id", primary_key: "batch_id"
  has_many :end_product_establishments, through: :priority_end_product_sync_queue
  after_initialize :init_counters

  ERROR_LIMIT = ENV["BATCH_PROCESS_MAX_ERRORS_BEFORE_STUCK"].to_i
  ERROR_DELAY = ENV["BATCH_PROCESS_ERROR_DELAY"].to_i
  BATCH_LIMIT = ENV["BATCH_PROCESS_BATCH_LIMIT"].to_i

  scope :completed_batch_process_ids, -> { where(state: Constants.BATCH_PROCESS.completed).select(:batch_id) }
  scope :needs_reprocessing, lambda {
    where("created_at <= ? AND state <> ?", BatchProcess::ERROR_DELAY.hours.ago, Constants.BATCH_PROCESS.completed)
  }

  enum state: {
    Constants.BATCH_PROCESS.pre_processing.to_sym => Constants.BATCH_PROCESS.pre_processing,
    Constants.BATCH_PROCESS.processing.to_sym => Constants.BATCH_PROCESS.processing,
    Constants.BATCH_PROCESS.completed.to_sym => Constants.BATCH_PROCESS.completed
  }

  class << self
    # A method for overriding, for the purpose of finding the records that
    # need to be batched. This method should return the records found.
    def find_records_to_batch
      # no-op, can be overwritten
    end

    # A method for orverriding, for the purpose of creating the batch and
    # associating the batch_id with the records gathered by the find_records method.
    def create_batch!(record)
      # no-op, can be overwritten
    end
  end

  # A method for overriding, for the purpose of processing the batch created
  # in the create_batch method. Processing can be anything, an example of which
  # is syncing up the records within the batch between caseflow and vbms.
  def process_batch!
    # no-op, can be overwritten
  end

  private

  # Instance var methods
  def init_counters
    @completed_count = 0
    @failed_count = 0
  end

  def increment_completed
    @completed_count += 1
  end

  def increment_failed
    @failed_count += 1
  end

  # State update Methods
  def batch_processing!
    update!(state: Constants.BATCH_PROCESS.processing, started_at: Time.zone.now)
  end

  def batch_complete!
    update!(state: Constants.BATCH_PROCESS.completed,
            records_failed: @failed_count,
            records_completed: @completed_count,
            ended_at: Time.zone.now)
  end

  # When a record and error is sent to this method, it updates the record and checks to see
  # if the record should be declared stuck. If the records should be stuck, it calls the
  # declare_record_stuck method (Found in priority_end_product_sync_queue.rb).
  # Otherwise, the record is updated with status: error and the error message is added to
  # error_messages.
  #
  # As a general method, it's assumed the record has a batch_id and error_messages
  # column within the associated table.
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
