# frozen_string_literal: true

# TODO: Transform these into where statements so we can run them proactively.
module TaskCondition
  def self.ama_appeal(task, _user)
    # Task.where(type: task.type).where(appeal_type: Appeal.name).include?(task)
    task.appeal&.is_a?(Appeal)
  end

  def self.assigned_to_me(task, user)
    # TODO: How do we handle proactive calculation when it depends on current user?
    task.assigned_to &.== user
  end

  def self.judge_task(task, _user)
    task.is_a?(JudgeTask)
  end

  def self.legacy_appeal(task, _user)
    task.appeal&.is_a?(LegacyAppeal)
  end

  def self.not_assigned_to_me(task, user)
    task.assigned_to &.!= user
  end

  def self.on_timed_hold(task, _user)
    task.on_timed_hold?
  end

  def self.parent_assigned_to_me(task, user)
    assigned_to_me(task.parent, user)
  end

  def self.parent_is_a_judge_task(task, user)
    judge_task(task.parent, user)
  end
end
