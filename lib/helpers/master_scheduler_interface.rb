# frozen_string_literal: true

module MasterSchedulerInterface

  def perform
    raise NotImplementedError, "The 'perform' method must be implemented in the including class."
  end

  def error_text
    raise NotImplementedError, "The 'error_text' method must be implemented in the including class."
  end

  def records_with_errors
    raise NotImplementedError, "The 'records_with_errors' method must be implemented in the including class."
  end

  def process_records
    raise NotImplementedError, "The 'process_records' method must be implemented in the including class."
  end
end
