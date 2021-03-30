# frozen_string_literal: true

##
# Task created by the mail team when mail arrives for a CAVC Appeal which is in processing with the CAVC Litigation
# Support team. May or not end up being related to CAVC response.
#
# Expected Parent Task: RootTask
#
# Expected Child Task: CavcCorrespondenceMailTask
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class CavcCorrespondenceMailTask < MailTask
  validate :cavc_appeal_stream, on: :create
  validate :appeal_at_cavc_lit_support, on: :create

  def self.label
    COPY::CAVC_CORRESPONDENCE_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    CavcLitigationSupport.singleton
  end

  def available_actions(user)
    return [] unless CavcLitigationSupport.singleton.user_has_access?(user)

    return user_task_actions if user_task_assigned_to_cavc_lit_support

    return organization_task_actions if assigned_to_type == "Organization"

    []
  end

  private

  def cavc_appeal_stream
    if !appeal.cavc?
      fail Caseflow::Error::ActionForbiddenError,
           message: "CAVC Correspondence can only be added to Court Remand Appeals."
    end
  end

  def appeal_at_cavc_lit_support
    if !open_cavc_task
      fail Caseflow::Error::ActionForbiddenError,
           message: "CAVC Correspondence can only be added while the appeal is with CAVC Litigation Support."
    end
  end

  def open_cavc_task
    CavcTask.open.where(appeal_id: appeal.id).any?
  end

  def organization_task_actions
    [
      Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
      Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  def user_task_actions
    [
      Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
      Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
      Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  def user_task_assigned_to_cavc_lit_support
    assigned_to_type == "User" && assigned_to_cavc_lit_team_member
  end

  def assigned_to_cavc_lit_team_member
    CavcLitigationSupport.singleton.users.include?(assigned_to)
  end
end
