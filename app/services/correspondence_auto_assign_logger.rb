# frozen_string_literal: true

# For correspondence auto assignment, creates records of assignment attempts.
# A log for the entire auto assignment run is stored to BatchAutoAssignmentAttempt.
# Logs for reach assignment attempt are stroed to IndividualAutoAssignmentAttempt.

# :reek:FeatureEnvy
class CorrespondenceAutoAssignLogger
  def initialize(current_user, batch)
    self.current_user = current_user
    self.batch = batch
  end

  class << self
    def fail_run_validation(batch_auto_assignment_attempt_id:, msg:)
      failed_batch = BatchAutoAssignmentAttempt.find(batch_auto_assignment_attempt_id)

      return if failed_batch.blank?

      failed_batch.update!(
        status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error,
        error_info: { message: msg },
        errored_at: Time.current
      )
    end
  end

  def begin
    batch.update!(
      started_at: Time.current,
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started,
      num_nod_packages_assigned: 0,
      num_nod_packages_unassigned: 0,
      num_packages_assigned: 0,
      num_packages_unassigned: 0
    )
  end

  def end
    batch.assign_attributes(
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed,
      completed_at: Time.current
    )

    save_run_statistics
  end

  def error(msg:)
    batch.assign_attributes(
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error,
      error_info: { message: msg },
      errored_at: Time.current
    )

    save_run_statistics
  end

  def assigned(task:, started_at:, assigned_to:)
    correspondence = task.correspondence

    attempt = individual_auto_assignment_attempt
    attempt.assign_attributes(
      correspondence: correspondence,
      completed_at: Time.current,
      nod: correspondence.nod,
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed,
      started_at: started_at
    )

    if correspondence.nod
      batch.num_nod_packages_assigned += 1
    else
      batch.num_packages_assigned += 1
    end

    save_attempt_statistics(
      attempt: attempt,
      task: task,
      result: "Correspondence #{correspondence.id} assigned to User ID #{assigned_to.id}"
    )
  end

  def no_eligible_assignees(task:, started_at:, unassignable_reason:)
    correspondence = task.correspondence

    attempt = individual_auto_assignment_attempt
    attempt.assign_attributes(
      correspondence: correspondence,
      errored_at: Time.current,
      nod: correspondence.nod,
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error,
      started_at: started_at
    )

    if correspondence.nod
      batch.num_nod_packages_unassigned += 1
    else
      batch.num_packages_unassigned += 1
    end

    save_attempt_statistics(
      attempt: attempt,
      task: task,
      result: "No eligible assignees: #{unassignable_reason}"
    )
  end

  private

  attr_accessor :batch, :current_user

  def individual_auto_assignment_attempt
    IndividualAutoAssignmentAttempt.new(
      batch_auto_assignment_attempt: batch,
      user: current_user
    )
  end

  def save_run_statistics
    stats = {
      seconds_elapsed: seconds_elapsed(record: batch, status: batch.status)
    }

    batch.statistics = stats
    batch.save!
  end

  def save_attempt_statistics(attempt:, task:, result:)
    stats = {
      result: result,
      seconds_elapsed: seconds_elapsed(record: attempt, status: attempt.status),
      review_package_task_id: task.id
    }

    attempt.statistics = stats
    attempt.save!
  end

  # :reek:ControlParameter
  def seconds_elapsed(record:, status:)
    if status == Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed
      record.completed_at - record.started_at
    else
      record.errored_at - record.started_at
    end
  end
end
