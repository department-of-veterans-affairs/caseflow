# frozen_string_literal: true

# metadata about an ETL build per table

class ETL::BuildTable < ETL::Record
  self.table_name = "etl_build_tables"

  belongs_to :etl_build, class_name: "ETL::Build"
end
