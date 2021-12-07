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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: etl_build_tables
#
#  id            :bigint           not null, primary key
#  comments      :string
#  finished_at   :datetime         indexed
#  rows_deleted  :bigint
#  rows_inserted :bigint
#  rows_rejected :bigint
#  rows_updated  :bigint
#  started_at    :datetime         indexed
#  status        :string           indexed
#  table_name    :string           indexed
#  created_at    :datetime         not null, indexed
#  updated_at    :datetime         not null, indexed
#  etl_build_id  :bigint           not null, indexed
#
