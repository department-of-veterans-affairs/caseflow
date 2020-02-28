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

  SKIP_ASSOCIATIONS = %w[
    appeal_views
    claims_folder_searches
    request_decision_issues
    request_issues_updates
  ].freeze

  attr_reader :since_date

  def association_names
    @association_names ||= Appeal.reflections.keys.reject { |key| SKIP_ASSOCIATIONS.include?(key) }
  end

  def build_query
    clauses = associated_clauses
    clauses << "appeals.updated_at >= ?"
    number_of_placeholders = Array.new(clauses.size, since_date)
    appeals_joined_distinct.where(clauses.join(" OR "), *number_of_placeholders)
  end

  def appeals_joined_distinct
    Appeal.established.left_joins(association_names.map(&:to_sym)).distinct
  end

  def associated_clauses
    association_names.map do |association_name|
      association = Appeal.reflections[association_name]
      "#{association.table_name}.updated_at >= ?"
    end
  end
end
