# frozen_string_literal: true

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

    super
  end

  private

  def cavc_appeal_stream
    if !appeal.cavc?
      fail Caseflow::Error::ActionForbiddenError, message: "CAVC Correspondence can only be added to Court Remand Appeals."
    end
  end

  def appeal_at_cavc_lit_support
    if !open_cavc_task
      fail Caseflow::Error::ActionForbiddenError, message: "CAVC Correspondence can only be added while the appeal is with CAVC Litigation Support."
    end
  end

  def open_cavc_task
    CavcTask.open.where(appeal_id: appeal.id).any?
  end
end
