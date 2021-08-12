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
    # TODO: add other `belongs_to .* polymorphic = true`
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

  # TODO: refactor
  def find_orphaned_records(klass)
    association_id_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_id_column]
    association_type_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_type_column]
    association_method = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_method]

    puts "Checking #{klass}"
    orphaned_ids = orphan_records(klass).pluck(:id, association_type_column || "'-'", association_id_column)
    if orphaned_ids.any?
      message = <<~MSG
        Found #{klass.name} orphaned record:
          (id, #{association_type_column}, #{association_id_column})
          #{orphaned_ids.map(&:to_s).join('\n')}
      MSG
      puts message
      slack_service.send_notification(message)
    end

    if association_type_column
      puts "unusual_records"
      unusual_records = klass.unscoped # TODO needed?: .select(:id, association_id_column, association_type_column)
        .includes(association_method).where(association_id_column => nil)
        .where.not(association_type_column => nil)
        .select { |rec| rec.send(association_method).nil? }
      unusual_record_ids = unusual_records.pluck(:id)
      if unusual_record_ids.any?
        slack_service.send_notification("Found #{klass.name} record with nil #{association_id_column} " \
          "but non-nil #{association_type_column}: #{unusual_record_ids}")
      end
    end
  end

  # Maps the association_method to a hash containing all the possible types. Each hash entry is:
  #   name used for `includes` => the associated ActiveRecord class
  # TODO: use reflection on ama_appeal to get class or tablename
  POLYMORPHIC_TYPES = {
    appeal: { ama_appeal: Appeal, legacy_appeal: LegacyAppeal },
    hearing: { ama_hearing: Hearing, legacy_hearing: LegacyHearing }
  }

  def orphan_records(klass)
    association_id_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_id_column]
    association_type_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_type_column]
    association_method = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_method]
    if association_type_column
      # SQL query implementation options: https://sqlperformance.com/2012/12/t-sql-queries/left-anti-semi-join
      # Implementing query with NOT EXIST conveys the intent (and is also fast according to `EXPLAIN`).
      # Unfortunately, there's not a clean Rails way to call NOT EXISTS --
      # see https://stackoverflow.com/questions/13496375/rails-associations-not-exists-better-way
      # Using OUTER JOIN with a where-NULL clause is just as fast and easier to implement in Rails:

      # Left join with the table for each polymorphic type
      merged_query = POLYMORPHIC_TYPES[association_method].map do |includes_name, poly_class|
        klass.unscoped.includes(includes_name).where(poly_class.arel_table[:id].eq(nil))
      end.reduce(:merge)
      # only check for records where the _id column is not nil
      merged_query.where.not(association_id_column => nil)
    else
      klass.unscoped #TODO needed?: .select(:id, association_id_column, association_type_column)
        .includes(association_method).where.not(association_id_column => nil)
        .where(association_method.to_s.classify.constantize.table_name => { id: nil })
    end
  end
end
