# frozen_string_literal: true

class CorrespondenceAutoAssignLogger
  attr_reader :total_attempts, :failed_attempts_count, :successful_assignments,
              :failed_assignments, :batch_assignment, :current_assignment

  def initialize(current_user)
    @total_attempts = 0
    @failed_attempts_count = 0
    @failed_assignments = []
    @successful_assignments = []
    @current_user = current_user
  end

  def begin_logging
    create_batch_assignment
  end

  def end_logging(status)
    Rails.logger.info("#{@failed_attempts_count}/#{@total_attempts} failed")

    # Batch assignment update! method here with status
  end

  def log_single_attempt(user_id:, correspondence_id:)
    @total_attempts += 1
    create_single_assignment(user_id: user_id, correspondence_id: correspondence_id)
    # Assign individual attempt here to @current_assignment
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

  private

  def create_single_assignment(user_id:, correspondence_id:)
    # Create individual assignment attempt here using correspondence_id, user_id:, and @batch_assignment
    Rails.logger.info("IndividualAutoAssignmentAttempt created")
  end

  def create_batch_assignment
    # Create @batch_assignment here using @current_user
    Rails.logger.info("LOGGING started for BatchAutoAssignmentAttempt")
  end
end
