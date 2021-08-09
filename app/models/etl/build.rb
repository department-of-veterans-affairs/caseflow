# frozen_string_literal: true

# metadata about an ETL build

class ETL::Build < ETL::Record
  self.table_name = "etl_builds"

  enum status: {
    running: "running",
    complete: "complete",
    error: "error"
  }

  has_many :etl_build_tables, class_name: "ETL::BuildTable", foreign_key: "etl_build_id"

  attribute :started_at, :datetime, default: -> { Time.zone.now }
  attribute :status, default: -> { :running }

  def tables
    etl_build_tables.pluck(:table_name).compact
  end

  def built
    built = 0
    etl_build_tables.each { |ebt| built += ebt.rows_built }
    built
  end

  def build_for(table_name)
    etl_build_tables.find { |ebt| ebt.table_name == table_name }
  end
end
