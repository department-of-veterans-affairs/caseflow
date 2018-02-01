class CreateDocketSnapshots < ActiveRecord::Migration
  def change
    create_table :docket_snapshots do |t|
      t.integer    :docket_count
      t.date       :latest_docket_month
      t.timestamps
    end
  end
end
