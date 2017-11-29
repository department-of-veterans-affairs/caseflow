class IndexAppealSeriesIdOnAppeals < ActiveRecord::Migration
  disable_ddl_transaction!
  def change
    add_index :appeals, :appeal_series_id, algorithm: :concurrently
  end
end
