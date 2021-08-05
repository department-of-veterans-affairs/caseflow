# frozen_string_literal: true

class ForeignKeyPolymorphicAssociationJob < CaseflowJob
  queue_with_priority :low_priority

  CLASSES_WITH_POLYMORPH_ASSOC = {
    Claimant => { association_id_column: :participant_id,
                  association_type_column: nil,
                  association_method: :person },
    # Claimant => { association_id_column: :decision_review_id,
    #               association_type_column: :decision_review_type,
    #               association_method: :decision_review },
    HearingEmailRecipient => { association_id_column: :hearing_id,
                               association_type_column: :hearing_type,
                               association_method: :hearing },
    SentHearingEmailEvent => { association_id_column: :hearing_id,
                               association_type_column: :hearing_type,
                               association_method: :hearing },
    SpecialIssueList => { association_id_column: :appeal_id,
                          association_type_column: :appeal_type,
                          association_method: :appeal },
    Task => { association_id_column: :appeal_id,
              association_type_column: :appeal_type,
              association_method: :appeal },
    VbmsUploadedDocument => { association_id_column: :appeal_id,
                              association_type_column: :appeal_type,
                              association_method: :appeal }
  }.freeze

  def perform
    # RequestStore.store[:current_user] = User.system_user

    CLASSES_WITH_POLYMORPH_ASSOC.keys.map do |klass|
      find_orphaned_records(klass)
    end
  end

  def find_orphaned_records(klass)
    association_id_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_id_column]
    association_method = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_method]

    # TODO: Change/optimize this query to address claimant.person not returning nil after person.destroy!
    orphan_records = klass.unscoped.includes(association_method).where.not(association_id_column => nil)
      .select { |rec| rec.send(association_method).nil? }
    if orphan_records.any?
      slack_service.send_notification("Found #{klass.name} orphaned record: #{orphan_records.map(&:id)}")
    end

    association_type_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_type_column]
    if association_type_column
      unusual_records = klass.unscoped.includes(association_method).where(association_id_column => nil)
        .where.not(association_type_column => nil)
        .select { |rec| rec.send(association_method).nil? }
      if unusual_records.any?
        slack_service.send_notification("Found #{klass.name} record with nil #{association_id_column} " \
          "but non-nil #{association_type_column}: #{unusual_records.map(&:id)}")
      end
    end
  end
end
