# frozen_string_literal: true

# Data integrity checker for notifying when an appeal has multiple open root-children task types
class MultipleOpenRootChildTaskChecker < DataIntegrityChecker
  # Task types where only one of any of these root-children task types should be open at a time.
  EXCLUSIVE_OPEN_TASKS ||= %w[DistributionTask
                              JudgeAssignTask
                              JudgeDecisionReviewTask
                              QualityReviewTask
                              BvaDispatchTask].freeze

  def call
    build_report(appeals_with_multiple_exclusive_open_tasks_assigned_to_user)
  end

  def slack_channel
    "#appeals-echo"
  end

  private

  # This efficient query is an approximation to the query we really want.
  def appeals_with_multiple_exclusive_open_tasks_assigned_to_user
    Task.open.assigned_to_any_user.where(type: EXCLUSIVE_OPEN_TASKS)
      .group(:appeal_type, :appeal_id).having("count(*) > 1").count
  end

  def open_root_tasks
    RootTask.open
  end

  def appeals_with_more_than_one_open_root_child_task
    # query is complex
  end

  def build_report(appeals)
    return if appeals.empty?

    count = appeals.count
    add_to_report "Found #{count} #{'appeal'.pluralize(count)} with multiple open root-children task types:"
    add_to_report appeals.entries.map { |appeal, count| "#{appeal.join(' ')} => #{count} tasks"}.join(", ")
  end
end
