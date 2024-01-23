# frozen_string_literal: true

class CorrespondenceAutoAssignLogger
  def initialize
    @total_attempts = 0
    @failed_attempts_count = 0
    @failed_assignments = []
    @successful_assignments = []
  end

  def begin_logging
    create_batch_assignment
    Rails.logger.info("LOGGING started for BatchAutoAssignment ID:#{@batch_assignment_attempt.id}")
  end

  def end_logging
    Rails.logger.info("#{@failed_attempts_count}/#{@total_attempts} failed")

    # Batch assignment update! method here
  end

  def log_single_attempt(correspondence_id:)
    @total_attempts += 1
    @current_assignment = SingleAutoAssignAttempt.create!
  end

  private

  def create_single_assignment
    # Create method here for batch auto assignment
    @batch_assignment_attempt = BatchAutoAssignment.create! if @batch_assignment_attempt.nil?
    Rails.logger.info("LOGGING started for BatchAutoAssignment ID:#{@batch_assignment_attempt.id}")
  end

  def create_batch_assignment
    # Create method here for batch auto assignment
    @batch_assignment_attempt = BatchAutoAssignment.create! if @batch_assignment_attempt.nil?
  end

  def record_failure
    @failed_attempts_count += 1
    @failed_assignments.push(@current_assignment)
    @current_assignment = nil
  end

  def record_success
    @successful_assignments.push(@current_assignment)
    @current_assignment = nil
  end
end
