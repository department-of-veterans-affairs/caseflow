# frozen_string_literal: true

##
# Tasks that block scheduling a Veteran for a hearing.
# A hearing coordinator must resolve these before scheduling a Veteran.
# Subclasses of various admin actions are defined below.

class HearingAdminActionTask < GenericTask
  validates :parent, presence: true
  validate :on_hold_duration_is_set, on: :update

  def self.child_task_assignee(parent, params)
    if params[:assigned_to_type] && params[:assigned_to_id]
      super(parent, params)
    else
      HearingsManagement.singleton
    end
  end

  def label
    self.class.label || "Hearing admin action"
  end

  # We need to allow multiple tasks to be assigned to the organization since all tasks will start there and be
  # manually distributed to users.
  def verify_org_task_unique
    true
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if assigned_to == user
      [
        Constants.TASK_ACTIONS.PLACE_HOLD.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ] | hearing_admin_actions
    elsif task_is_assigned_to_users_organization?(user)
      [
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h
      ] | hearing_admin_actions
    else
      hearing_admin_actions
    end
  end

  def actions_allowable?(user)
    (HearingsManagement.singleton.user_has_access?(user) || HearingAdmin.singleton.user_has_access?(user)) && super
  end

  private

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end

class HearingAdminActionVerifyPoaTask < HearingAdminActionTask
  def self.label
    "Verify power of attorney"
  end
end
class HearingAdminActionIncarceratedVeteranTask < HearingAdminActionTask
  def self.label
    "Veteran is incarcerated"
  end
end
class HearingAdminActionContestedClaimantTask < HearingAdminActionTask
  def self.label
    "Contested claimant issue"
  end
end
class HearingAdminActionMissingFormsTask < HearingAdminActionTask
  def self.label
    "Missing forms"
  end
end
class HearingAdminActionFoiaPrivacyRequestTask < HearingAdminActionTask
  def self.label
    "FOIA/Privacy request"
  end
end
class HearingAdminActionForeignVeteranCaseTask < HearingAdminActionTask
  def self.label
    "Foreign Veteran case"
  end
end
class HearingAdminActionOtherTask < HearingAdminActionTask
  def self.label
    "Other"
  end
end
