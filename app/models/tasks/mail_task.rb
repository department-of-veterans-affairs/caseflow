class MailTask < GenericTask
  # Skip unique verification for mail tasks since multiple mail tasks of each type can be created.
  def verify_org_task_unique; end

  class << self
    def subclass_routing_options
      MailTask.subclasses.sort_by(&:label).map { |subclass| { value: subclass.name, label: subclass.label } }
    end

    def create_from_params(params, user)
      verify_user_can_create!(user, Task.find(params[:parent_id]))

      root_task = RootTask.find(params[:parent_id])

      # Do not create the parent mail task if we fail to create any of the children tasks.
      transaction do
        # Create a task assigned to the mail organization with a child task so we can track how that child was created.
        mail_task = create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: MailTeam.singleton
        )

        params = modify_params(params)
        create_child_task(mail_task, user, params)
      end
    end

    def outstanding_cavc_tasks?(_parent)
      # We don't yet create CAVC tasks so this will always return false for now.
      false
    end

    def pending_hearing_task?(parent)
      # TODO: Update this function once AMA appeals start to be held (sometime after 14 FEB 19). Right now this expects
      # that every AMA appeal that is on the hearing docket has a pending hearing task.
      parent.appeal.hearing_docket?
    end

    def case_active?(parent)
      parent.appeal.active?
    end

    def most_recent_active_task_assignee(parent)
      parent.appeal.tasks.active.where(assigned_to_type: User.name).order(:created_at).last&.assigned_to
    end
  end

  def label
    self.class.label
  end
end

class AddressChangeMailTask < MailTask
  def self.label
    COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(parent, _params)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    return HearingsManagement.singleton if pending_hearing_task?(parent)

    Colocated.singleton
  end
end

class AodMotionMailTask < MailTask
  def self.label
    COPY::AOD_MOTION_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    AodTeam.singleton
  end
end

class AppealWithdrawalMailTask < MailTask
  def self.label
    COPY::APPEAL_WITHDRAWAL_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    Colocated.singleton
  end
end

class ClearAndUnmistakeableErrorMailTask < MailTask
  def self.label
    COPY::CLEAR_AND_UNMISTAKABLE_ERROR_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end

class CongressionalInterestMailTask < MailTask
  def self.label
    COPY::CONGRESSIONAL_INTEREST_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end

class ControlledCorrespondenceMailTask < MailTask
  def self.label
    COPY::CONTROLLED_CORRESPONDENCE_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end

class DeathCertificateMailTask < MailTask
  def self.label
    COPY::DEATH_CERTIFICATE_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    Colocated.singleton
  end
end

class EvidenceOrArgumentMailTask < MailTask
  def self.label
    COPY::EVIDENCE_OR_ARGUMENT_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(parent, _params)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    return HearingsManagement.singleton if pending_hearing_task?(parent)

    Colocated.singleton
  end
end

class ExtensionRequestMailTask < MailTask
  def self.label
    COPY::EXTENSION_REQUEST_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(parent, _params)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    Colocated.singleton
  end
end

class FoiaRequestMailTask < MailTask
  def self.label
    COPY::FOIA_REQUEST_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    PrivacyTeam.singleton
  end
end

class HearingRelatedMailTask < MailTask
  def self.label
    COPY::HEARING_RELATED_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(parent, _params)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    return HearingsManagement.singleton if pending_hearing_task?(parent)

    Colocated.singleton
  end
end

class OtherMotionMailTask < MailTask
  def self.label
    COPY::OTHER_MOTION_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end

class PowerOfAttorneyRelatedMailTask < MailTask
  def self.label
    COPY::POWER_OF_ATTORNEY_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(parent, _params)
    fail Caseflow::Error::MailRoutingError unless case_active?(parent)

    return HearingsManagement.singleton if pending_hearing_task?(parent)

    Colocated.singleton
  end
end

class PrivacyActRequestMailTask < MailTask
  def self.label
    COPY::PRIVACY_ACT_REQUEST_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    PrivacyTeam.singleton
  end
end

class PrivacyComplaintMailTask < MailTask
  def self.label
    COPY::PRIVACY_COMPLAINT_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    PrivacyTeam.singleton
  end
end

class ReturnedUndeliverableCorrespondenceMailTask < MailTask
  def self.label
    COPY::RETURNED_CORRESPONDENCE_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(parent, _params)
    return BvaDispatch.singleton if !case_active?(parent)
    return HearingsManagement.singleton if pending_hearing_task?(parent)
    return most_recent_active_task_assignee(parent) if most_recent_active_task_assignee(parent)

    fail Caseflow::Error::MailRoutingError
  end
end

class ReconsiderationMotionMailTask < MailTask
  def self.label
    COPY::RECONSIDERATION_MOTION_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end

class StatusInquiryMailTask < MailTask
  def self.label
    COPY::STATUS_INQUIRY_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end

class VacateMotionMailTask < MailTask
  def self.label
    COPY::VACATE_MOTION_MAIL_TASK_LABEL
  end

  def self.child_task_assignee(_parent, _params)
    LitigationSupport.singleton
  end
end
