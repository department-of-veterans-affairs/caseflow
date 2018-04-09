class AddSeriesIdToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :series_id, :string
  end
end
