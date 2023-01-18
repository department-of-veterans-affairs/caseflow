# frozen_string_literal: true

class ForeignKeyPolymorphicAssociationJob < CaseflowJob
  queue_with_priority :low_priority

  APPEAL_ASSOCIATION_DETAILS = { id_column: :appeal_id,
                                 type_column: :appeal_type,
                                 includes_method: :appeal }.freeze
  HEARING_ASSOCIATION_DETAILS = { id_column: :hearing_id,
                                  type_column: :hearing_type,
                                  includes_method: :hearing }.freeze

  # comes from polymorphic associations listed in immigrant.rb
  CLASSES_WITH_POLYMORPH_ASSOC = {
    Claimant => [
      { # participant_id could refer to the `people` or `bgs_attorneys` tables
        id_column: :participant_id,
        type_column: nil,
        includes_method: :person,
        # Exclude OtherClaimant (unrecognized appellants) and AttorneyClaimant
        scope: -> { where(type: "VeteranClaimant") }
      },
      { id_column: :decision_review_id,
        type_column: :decision_review_type,
        includes_method: :decision_review }
    ],

    HearingEmailRecipient => [HEARING_ASSOCIATION_DETAILS],
    SentHearingEmailEvent => [HEARING_ASSOCIATION_DETAILS],

    AvailableHearingLocations => [APPEAL_ASSOCIATION_DETAILS],
    AttorneyCaseReview => [APPEAL_ASSOCIATION_DETAILS],
    JudgeCaseReview => [APPEAL_ASSOCIATION_DETAILS],
    SpecialIssueList => [APPEAL_ASSOCIATION_DETAILS],

    Task => [
      { id_column: :appeal_id,
        type_column: :appeal_type,
        includes_method: :task_appeal }
    ]
  }.freeze

  def perform
    CLASSES_WITH_POLYMORPH_ASSOC.map do |klass, configs|
      configs.each do |config|
        find_bad_records(klass, config)
      end
    end
  end

  # :reek:FeatureEnvy
  def find_bad_records(klass, config)
    select_fields = [:id, config[:type_column] || Arel::Nodes::SqlLiteral.new("NULL"), config[:id_column]]

    already_reported_ids = []
    if config[:type_column]
      unusual_record_ids = unusual_records(klass, config).pluck(*select_fields)
      heading = "Found #{unusual_record_ids.size} unusual records " \
                "(nil #{config[:type_column]} or #{config[:id_column]})"
      send_alert(heading, klass, config, unusual_record_ids) if unusual_record_ids.any?

      already_reported_ids = unusual_record_ids.map(&:first)
    end

    orphaned_ids = scoped_orphan_records(klass, config).pluck(*select_fields)
    unreported_orphaned_ids = orphaned_ids.reject { |id, _, _| already_reported_ids.include?(id) }
    heading = "Found #{unreported_orphaned_ids.size} orphaned records"
    send_alert(heading, klass, config, unreported_orphaned_ids) if unreported_orphaned_ids.any?
  end

  # :reek:LongParameterList
  # :reek:FeatureEnvy
  def send_alert(heading, klass, config, record_ids)
    message = <<~MSG
      #{heading} for #{klass.name}:
      (id, #{config[:type_column]}, #{config[:id_column]})
      #{record_ids.map(&:to_s).join("\n")}
    MSG
    slack_service.send_notification(message, "#{klass.name} orphaned records via #{config[:id_column]}",
                                    "#appeals-data-workgroup")
  end

  # Maps the includes_method to a hash containing all the possible types. Each hash entry is:
  #   name used for `includes` => the associated ActiveRecord class
  POLYMORPHIC_TYPES = {
    appeal: {
      ama_appeal: Appeal,
      legacy_appeal: LegacyAppeal
    },
    task_appeal: {
      ama_appeal: Appeal,
      legacy_appeal: LegacyAppeal,
      # SC and HLR records can have Tasks
      supplemental_claim: SupplementalClaim,
      higher_level_review: HigherLevelReview
    },
    hearing: { ama_hearing: Hearing, legacy_hearing: LegacyHearing },
    decision_review: {
      ama_appeal: Appeal,
      legacy_appeal: LegacyAppeal,
      supplemental_claim: SupplementalClaim,
      higher_level_review: HigherLevelReview
    }
  }.freeze

  def orphan_records(klass, config)
    includes_method = config[:includes_method]
    if config[:type_column]
      # SQL query implementation options: https://sqlperformance.com/2012/12/t-sql-queries/left-anti-semi-join
      # Implementing query with NOT EXIST conveys the intent (and is also fast according to `EXPLAIN`).
      # Unfortunately, there's not a clean Rails way to call NOT EXISTS --
      # see https://stackoverflow.com/questions/13496375/rails-associations-not-exists-better-way
      # Using OUTER JOIN with a where-NULL clause is just as fast and easier to implement in Rails:

      # Left join with the table associated with each polymorphic type
      merged_query = POLYMORPHIC_TYPES[includes_method].map do |includes_name, poly_class|
        klass.unscoped.includes(includes_name).where(poly_class.arel_table[:id].eq(nil))
      end.reduce(:merge)
      # only check for records where the _id column is not nil
      merged_query.where.not(config[:id_column] => nil).order(config[:id_column], :id)
    else
      klass.unscoped.includes(includes_method)
        .where(includes_method.to_s.classify.constantize.table_name => { id: nil })
        .where.not(config[:id_column] => nil).order(config[:id_column], :id)
    end
  end

  def scoped_orphan_records(klass, config)
    return orphan_records(klass, config).merge(config[:scope]) if config[:scope]

    orphan_records(klass, config)
  end

  def unusual_records(klass, config)
    nil_id_query = klass.unscoped.where(config[:id_column] => nil).where.not(config[:type_column] => nil)
    nil_type_query = klass.unscoped.where.not(config[:id_column] => nil).where(config[:type_column] => nil)

    # https://stackoverflow.com/questions/6686920/activerecord-query-union
    sub_query = [nil_id_query, nil_type_query].map { |query| query.select(:id).to_sql }.join(" UNION ")
    klass.unscoped.where(
      Arel::Nodes::In.new(
        klass.arel_table[:id],
        Arel::Nodes::SqlLiteral.new(sub_query)
      )
    )
  end
end
