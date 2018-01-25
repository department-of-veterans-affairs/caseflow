class AddDocumentsIndexToSeriesId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :documents, :series_id, unique: true, algorithm: :concurrently
  end
end
