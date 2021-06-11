# frozen_string_literal: true

##
# Task assigned to BVA Dispatch team members whenever a judge completes a case review.
# This indicates that an appeal is decided and the appellant is about to be notified of the decision.

class BvaDispatchTask < Task
  before_create :prevent_dispatch_task_creation_for_unrecognized_appellants

  def available_actions(user)
    return [] unless user

    actions = super(user)
    if assigned_to == user || parent.task_is_assigned_to_organization_user_administers?(user)
      actions.unshift(Constants.TASK_ACTIONS.DISPATCH_RETURN_TO_JUDGE.to_h)
      actions.delete(Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h)
      actions.delete(Constants.TASK_ACTIONS.MARK_COMPLETE.to_h)
    end

    actions
  end

  def task_is_assigned_to_organization_user_administers?(user)
    task_is_assigned_to_users_organization?(user) && user.administered_teams.include?(assigned_to)
  end

  class << self
    def create_from_root_task(root_task)
      return unless ready_for_dispatch?(root_task.appeal)

      create!(assigned_to: BvaDispatch.singleton, parent_id: root_task.id, appeal: root_task.appeal)
    end

    TASK_TYPES_BLOCKING_DISPATCH = [:QualityReviewTask].freeze

    def ready_for_dispatch?(appeal)
      return false if appeal.tasks.open.where(type: TASK_TYPES_BLOCKING_DISPATCH).any?

      true
    end

    def outcode(appeal, params, user)
      if appeal.is_a?(Appeal)
        AmaAppealDispatch.new(appeal: appeal, user: user, params: params).call
      elsif appeal.is_a?(LegacyAppeal)
        LegacyAppealDispatch.new(appeal: appeal, params: params).call
      end
    end
  end

  private

  def prevent_dispatch_task_creation_for_unrecognized_appellants
      fail NotImplementedError if appeal.claimant.is_a?(OtherClaimant)
  end
end
