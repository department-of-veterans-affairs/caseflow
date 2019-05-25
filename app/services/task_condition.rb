# frozen_string_literal: true

module TaskCondition
  def self.ama_appeal(task, _user)
    task&.appeal&.is_a?(Appeal)
  end

  def self.assigned_to_me(task, user)
    task&.assigned_to &.== user
  end

  def self.judge_task(task, _user)
    task.is_a?(JudgeTask)
  end

  def self.legacy_appeal(task, _user)
    task&.appeal&.is_a?(LegacyAppeal)
  end

  def self.not_assigned_to_me(task, user)
    task&.assigned_to &.!= user
  end

  def self.parent_assigned_to_me(task, user)
    assigned_to_me(task&.parent, user)
  end

  def self.parent_is_a_judge_task(task, user)
    judge_task(task&.parent, user)
  end
end
