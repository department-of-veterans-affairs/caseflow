class AddDocumentsIndexToSeriesId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :documents, :series_id, algorithm: :concurrently
  end
end
