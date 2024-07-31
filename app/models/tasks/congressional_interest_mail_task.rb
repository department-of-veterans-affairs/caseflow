# frozen_string_literal: true

class CongressionalInterestMailTask < MailTask
  def self.blocking?
    true
  end

  def self.label
    COPY::CONGRESSIONAL_INTEREST_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end

  def available_actions(user)
    return [] unless user

    options = [
      Constants.TASK_ACTIONS.CHANGE_CORR_TASK_TYPE.to_h,
      Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.MARK_TASK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.RETURN_TO_INBOUND_OPS.to_h,
      Constants.TASK_ACTIONS.CANCEL_CORR_TASK.to_h
    ]

    if user.assigned_to.name == User.name
      options.insert(2, Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h)
    else
      options.insert(2, Constants.TASK_ACTIONS.REASSIGN_CORR_TASK_TO_PERSON.to_h)
    end

    options
  end
end
