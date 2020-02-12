# frozen_string_literal: true

# metadata about an ETL build

class ETL::Build < ETL::Record
  self.table_name = "etl_builds"

  has_many :etl_build_tables, class_name: "ETL::BuildTable", foreign_key: "etl_build_id"
end
