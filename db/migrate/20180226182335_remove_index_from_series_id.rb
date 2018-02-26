class RemoveIndexFromSeriesId < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    remove_index :documents, :series_id
  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
