# frozen_string_literal: true

# Match any Appeal or its associations that have been updated since a baseline date.
#

class AppealsUpdatedSinceQuery
  def initialize(since_date:)
    @since_date = since_date
  end

  def call
    build_query
  end

  private

  # Before adding to this list, consider adding `include HasAppealUpdatedSince` 
  # or `scope :updated_since_for_appeals` to the model, esp. if the ETL::Appeal table uses the model's data.
  SKIP_ASSOCIATIONS = %w[
    versions
    appeal_views
    claims_folder_searches
    job_notes
    nod_date_updates
    record_synced_by_job
    request_decision_issues
    request_issues_updates
  ].freeze

  attr_reader :since_date

  def association_names
    @association_names ||= Appeal.reflections.keys.reject { |key| SKIP_ASSOCIATIONS.include?(key) }
  end

  def build_query
    Appeal.established.where("appeals.updated_at >= ?", since_date)
      .or(Appeal.established.where("appeals.id IN (#{clauses_union})"))
  end

  def clauses_union
    updated_since_for_appeals_relations.map(&:arel).map(&:to_sql).join("\n UNION ")
  end

  def updated_since_for_appeals_relations
    association_names.map do |association_name|
      association = Appeal.reflections[association_name]
      assoc_klass = association.klass
      assoc_klass.updated_since_for_appeals(since_date)
    end
  end
end
