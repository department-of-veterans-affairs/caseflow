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
    # HearingEmailRecipient => { association_id_column: :hearing_id,
    #                            association_type_column: :hearing_type,
    #                            association_method: :hearing },
    # SentHearingEmailEvent => { association_id_column: :hearing_id,
    #                            association_type_column: :hearing_type,
    #                            association_method: :hearing },
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
    association_method = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_method]

    # TODO: Change/optimize this query to address claimant.person not returning nil after person.destroy!
    # Also claimant.person calls find_or_create_by_participant_id, which is not read-only
    puts "Checking #{klass}"
    # Claimant.unscoped.includes(:person).where.not(participant_id: nil).where(people: { id: nil }).pluck(:id)
    # Claimant.unscoped.includes(:person).where.not(participant_id: nil).select { |rec| rec.send(:person).nil? }.pluck(:id)
    # binding.pry
    association_type_column = CLASSES_WITH_POLYMORPH_ASSOC[klass][:association_type_column]
    orphan_records = nil
    if false && association_type_column
      puts "potentially inefficient if rec.send(association_method) is a method that calls .find_*"
      binding.pry
      # 2 queries: preload + load association
      orphan_records = klass.unscoped.select(:id, association_id_column, association_type_column)
        .includes(association_method).where.not(association_id_column => nil)
        .select { |rec| rec.send(association_method).nil? }.pluck(:id)
    elsif association_type_column
      # SQL query implementation options: https://sqlperformance.com/2012/12/t-sql-queries/left-anti-semi-join
      # Implementing query with NOT EXIST conveys the intent (and is also fast according to `EXPLAIN`).
      # Unfortunately, there's not a clean Rails way to call NOT EXISTS --
      # see https://stackoverflow.com/questions/13496375/rails-associations-not-exists-better-way
      # Using OUTER JOIN with a where-NULL clause is just as fast and easier to implement in Rails.
      orphan_records_ama = klass.unscoped.includes(:ama_appeal).where.not(association_id_column => nil)
        .where(Appeal.arel_table[:id].eq(nil))
      orphan_records_legacy = klass.unscoped.includes(:legacy_appeal).where.not(association_id_column => nil)
        .where(LegacyAppeal.arel_table[:id].eq(nil))
      orphan_records = orphan_records_ama.merge(orphan_records_legacy).pluck(:id)
      # binding.pry
    elsif association_method == :appeal
      puts "have to enumerate each type"
      self_table_name = klass.table_name
      orphan_records_ama = klass.unscoped.select(:id, association_id_column, association_type_column)
        .includes(:ama_appeal).where.not(association_id_column => nil)
        .where.not(Appeal.select('1').where("appeals.id = #{self_table_name}.#{association_id_column} AND 'Appeal' = #{self_table_name}.#{association_type_column}").arel.exists)
      orphan_records_legacy = klass.unscoped.select(:id, association_id_column, association_type_column)
        .includes(:legacy_appeal).where.not(association_id_column => nil)
        .where.not(LegacyAppeal.select('1').where("legacy_appeals.id = #{self_table_name}.#{association_id_column} AND 'LegacyAppeal' = #{self_table_name}.#{association_type_column}").arel.exists)
      orphan_records = orphan_records_ama.merge(orphan_records_legacy).pluck(:id)
      # binding.pry
    elsif false && association_type_column
      # BAD: associated_record_ids and found_ids must fit in memory
      associated_record_ids = klass.unscoped.where.not(association_id_column => nil).pluck(association_id_column)
      associated_class = association_method.to_s.classify.constantize  # TODO: have to enumerate each type
      found_ids = associated_class.where(id: associated_record_ids).pluck(:id)
      orphan_records = klass.unscoped.where(association_id_column => (associated_record_ids - found_ids)).pluck(:id)
    # elsif association_type_column
    #   orphan_records =  klass.unscoped.select(:id, association_id_column, association_type_column)
    #  .includes(association_method).where.not(association_id_column => nil)
    else
      orphan_records = klass.unscoped.select(:id, association_id_column, association_type_column)
        .includes(association_method).where.not(association_id_column => nil)
        .where(association_method.to_s.classify.constantize.table_name => { id: nil }).pluck(:id)
    end
    orphaned_ids = orphan_records #.pluck(:id)
    if orphaned_ids.any?
      slack_service.send_notification("Found #{klass.name} orphaned record: #{orphaned_ids}")
    end

    if association_type_column
      puts "unusual_records"
      unusual_records = klass.unscoped.select(:id, association_id_column, association_type_column)
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
end
