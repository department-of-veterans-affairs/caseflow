class AddDocumentsIndexToSeriesId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 900000" # 15 minutes

    add_index :documents, :series_id, unique: true, algorithm: :concurrently
  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
