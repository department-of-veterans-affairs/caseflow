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
    number_of_placeholders = Array.new(association_names.size, since_date)
    appeals_updated_since.distinct.where(associated_clauses.join(" OR "), *number_of_placeholders)
  end

  def appeals_updated_since
    Appeal.left_joins(association_names.map(&:to_sym)).where("appeals.updated_at >= ?", since_date)
  end

  def associated_clauses
    association_names.map do |association_name|
      association = Appeal.reflections[association_name]
      "#{association.table_name}.updated_at >= ?"
    end
  end

end
