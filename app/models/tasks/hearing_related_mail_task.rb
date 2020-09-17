# frozen_string_literal: true

class HearingRelatedMailTask < MailTask
  def self.blocking?
    true
  end

  def self.label
    COPY::HEARING_RELATED_MAIL_TASK_LABEL
  end

  def available_actions(user)
    default_actions = super(user)

    if task_is_assigned_to_user_within_admined_hearing_organization?(user)
      return default_actions | [Constants.TASK_ACTIONS.REASSIGN_TO_HEARINGS_TEAMS_MEMBER.to_h]
    end

    default_actions
  end

  def self.default_assignee(parent)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    return HearingAdmin.singleton if pending_hearing_task?(parent)

    Colocated.singleton
  end
end
