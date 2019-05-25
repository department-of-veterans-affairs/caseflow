# frozen_string_literal: true

# Transform these into where statements so we can run them proactively.
# - Task.where(type: task.type).where(appeal_type: Appeal.name).include?(task)
# - How do we handle proactive calculation when it depends on current user?
module TaskCondition
  def self.actions_for_active_set(sets, task, user)
    sets.each { |set| break set[:actions] if TaskCondition.condition_checker(set[:conditions], task, user) }
  end

  def self.condition_checker(conditions, task, user)
    conditions.map { |condition| TaskCondition.send(condition, task, user) }.all?(true)
  end

  # private

  def self.ama_appeal(task, _user)
    task.appeal&.is_a?(Appeal)
  end

  def self.assigned_to_me(task, user)
    task.assigned_to &.== user
  end

  def self.assigned_to_organization_user_belongs_to(task, user)
    task.assigned_to.is_a?(Organization) && task.assigned_to.user_has_access?(user)
  end

  def self.assigned_to_user_within_organization(task, user)
    task.parent&.assigned_to.is_a?(Organization) &&
      task.assigned_to.is_a?(User) &&
      task.parent.assigned_to.user_has_access?(user)
  end

  def self.judge_task(task, _user)
    task.is_a?(JudgeTask)
  end

  def self.legacy_appeal(task, _user)
    task.appeal&.is_a?(LegacyAppeal)
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
