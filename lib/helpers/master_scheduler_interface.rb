# frozen_string_literal: true

module MasterSchedulerInterface
  def perform
    fail NotImplementedError, "The 'perform' method must be implemented in the including class."
  end

  def error_text
    fail NotImplementedError, "The 'error_text' method must be implemented in the including class."
  end

  def records_with_errors
    fail NotImplementedError, "The 'records_with_errors' method must be implemented in the including class."
  end

  def process_records
    fail NotImplementedError, "The 'process_records' method must be implemented in the including class."
  end
end
