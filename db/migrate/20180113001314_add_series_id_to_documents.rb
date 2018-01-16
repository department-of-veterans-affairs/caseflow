class AddSeriesIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :series_id, :string
    add_index :documents, :series_id, algorithm: :concurrently
    add_index :documents, :file_number, algorithm: :concurrently
  end
end
