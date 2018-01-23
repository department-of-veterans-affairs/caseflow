class AddSeriesIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :series_id, :string
  end
end
