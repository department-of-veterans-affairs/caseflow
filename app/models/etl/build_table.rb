# frozen_string_literal: true

# metadata about an ETL build per table

class ETL::BuildTable < ETL::Record
  self.table_name = "etl_build_tables"

  enum status: {
    running: "running",
    complete: "complete",
    error: "error"
  }

  belongs_to :etl_build, class_name: "ETL::Build"

  def rows_built
    (rows_inserted || 0) + (rows_updated || 0) - (rows_deleted || 0)
  end
end
