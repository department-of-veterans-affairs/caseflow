# frozen_string_literal: true

##
# Task assigned to BVA Dispatch team members whenever a judge completes a case review.
# This indicates that an appeal is decided and the appellant is about to be notified of the decision.

class BvaDispatchTask < GenericTask
  def available_actions(user)
    return [] unless user

    actions = super(user)
    if assigned_to == user || parent.task_is_assigned_to_organization_user_administers?(user)
      actions.unshift(Constants.TASK_ACTIONS.DISPATCH_RETURN_TO_JUDGE.to_h)
    end

    actions
  end

  def task_is_assigned_to_organization_user_administers?(user)
    task_is_assigned_to_users_organization?(user) && user.administered_teams.include?(assigned_to)
  end

  class << self
    def create_from_root_task(root_task)
      create!(assigned_to: BvaDispatch.singleton, parent_id: root_task.id, appeal: root_task.appeal)
    end

    def outcode(appeal, params, user)
      if appeal.is_a?(Appeal)
        AmaAppealDispatch.new(appeal: appeal, user: user, params: params).call
      elsif appeal.is_a?(LegacyAppeal)
        LegacyAppealDispatch.new(appeal: appeal, params: params).call
      end
    end
  end
end
