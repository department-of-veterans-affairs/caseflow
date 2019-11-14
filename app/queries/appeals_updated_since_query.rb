# frozen_string_literal: true

class AppealsUpdatedSinceQuery
  def initialize(since_date:)
    @since_date = since_date
  end

  def call
    build_query
  end

  private

  attr_reader :since_date

  def association_names
    @association_names ||= Appeal.reflections.keys
  end

  def build_query
    clauses = associated_clauses
    clauses << "appeals.updated_at >= ?"
    number_of_placeholders = Array.new(clauses.size, since_date)
    appeals_joined_distinct.where(clauses.join(" OR "), *number_of_placeholders)
  end

  def appeals_joined_distinct
    Appeal.left_joins(association_names.map(&:to_sym)).distinct
  end

  def associated_clauses
    association_names.map do |association_name|
      association = Appeal.reflections[association_name]
      "#{association.table_name}.updated_at >= ?"
    end
  end

end
