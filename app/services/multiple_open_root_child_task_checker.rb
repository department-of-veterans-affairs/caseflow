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
    build_report(appeals_with_multiple_open_root_child_task)
  end

  def self.open_exclusive_root_children_tasks(appeal)
    appeal.tasks.open.of_type(EXCLUSIVE_OPEN_TASKS).where(parent: appeal.root_task)
  end

  private

  def appeals_with_multiple_open_root_child_task
    Task.open.where(type: EXCLUSIVE_OPEN_TASKS, parent: open_root_tasks)
      .select("appeal_type, appeal_id")
      .group(:appeal_type, :appeal_id).having("count(*) > 1")
      .map(&:appeal).uniq
  end

  def open_root_tasks
    RootTask.open
  end

  def build_report(appeals)
    return if appeals.empty?

    count = appeals.count
    add_to_report "Found #{count} #{'appeal'.pluralize(count)} with multiple open root-children task types:"

    appeal_list = appeals.map do |appeal|
      open_task_types = self.class.open_exclusive_root_children_tasks(appeal).pluck(:type, :id)
      "#{appeal.class} #{appeal.id} => #{open_task_types.size} tasks: #{open_task_types}"
    end
    add_to_report appeal_list.join("\n")
  end
end
