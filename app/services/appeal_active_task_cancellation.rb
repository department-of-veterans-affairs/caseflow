# frozen_string_literal: true

class AppealActiveTaskCancellation
  delegate :request_issues, :tasks, to: :appeal

  def initialize(appeal)
    @appeal = appeal
  end

  def call
    if appeal.withdrawn?
      # Withdrawn appeals must be included in the automatic distribution pool.
      # For an appeal to be considered ready for distribution, it must have an
      # assigned DistributionTask. In order for the appeal to progress after
      # distribution, its RootTask and TrackVeteranTask cannot be cancelled.
      cancel_active_tasks_except_those_needed_for_distribution
      assign_distribution_task
    elsif no_active_request_issues?
      cancel_active_tasks
    end
  end

  private

  attr_reader :appeal

  def cancel_active_tasks_except_those_needed_for_distribution
    all_tasks_except_those_needed_for_distribution.each(&:cancel_task_and_child_subtasks)
  end

  def assign_distribution_task
    tasks.find_by(type: "DistributionTask").update!(status: Constants.TASK_STATUSES.assigned)
  end

  def all_tasks_except_those_needed_for_distribution
    tasks.where.not(type: tasks_needed_for_distribution)
  end

  def tasks_needed_for_distribution
    %w[TrackVeteranTask RootTask]
  end

  def no_active_request_issues?
    request_issues.active.empty?
  end

  def cancel_active_tasks
    tasks.each(&:cancel_task_and_child_subtasks)
  end
end
