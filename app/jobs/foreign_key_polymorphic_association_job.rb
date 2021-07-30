# frozen_string_literal: true

class ForeignKeyPolymporphicAssociationJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    RequestStore.store[:current_user] = User.system_user
 
    find_orphaned_records
  end

  def find_orphaned_records
    # sent_hearing_email_events = SentHearingEmailEvent.unscoped.includes(:hearing).where.not(hearing_id: nil).select{|she| she.hearing == nil}
    # hearing_email_recipients = HearingEmailRecipient.unscoped.includes(:hearing).where.not(hearing_id: nil).select{|her| her.hearing == nil}
    # special_issue_lists = SpecialIssueList.unscoped.includes(:appeal).where.not(appeal_id: nil).select{|sil| sil.appeal == nil}
    # tasks = Task.unscoped.includes(:appeal).where.not(appeal_id: nil).select{|t| t.appeal == nil}
    # vbms_uploaded_documents = VbmsUploadedDocument.unscoped.includes(:appeal).where.not(appeal_id: nil).select{|vbms| vbms.appeal == nil}
  end
end
