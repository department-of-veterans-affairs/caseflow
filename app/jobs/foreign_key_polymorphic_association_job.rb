# frozen_string_literal: true

class ForeignKeyPolymorphicAssociationJob < CaseflowJob
  queue_with_priority :low_priority

  CLASSES_WITH_POLYMORPH_ASSOC = {
    SpecialIssueList => { association_id_column: :appeal_id, association_method: :appeal },
    Task => { association_id_column: :appeal_id, association_method: :appeal },
    VbmsUploadedDocument => { association_id_column: :appeal_id, association_method: :appeal }
  }.freeze
  # SentHearingEmailEvent.unscoped.includes(:hearing).where.not(hearing_id: nil).select{|she| she.hearing == nil}
  # HearingEmailRecipient.unscoped.includes(:hearing).where.not(hearing_id: nil).select{|her| her.hearing == nil}
  # VbmsUploadedDocument.unscoped.includes(:appeal).where.not(appeal_id: nil).select{|vbms| vbms.appeal == nil}

  def perform
    # RequestStore.store[:current_user] = User.system_user

    CLASSES_WITH_POLYMORPH_ASSOC.keys.map do |klass|
      find_orphaned_records(klass)
    end
  end

  def find_orphaned_records(klass)
    association_id_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_id_column]
    association_method = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_method]
    orphan_records = klass.unscoped.includes(association_method).where.not(association_id_column => nil)
      .select { |rec| rec.send(association_method).nil? }
    if orphan_records.any?
      slack_service.send_notification("Found #{klass.name} orphaned record: #{orphan_records.map(&:id)}")
    end
  end
end
