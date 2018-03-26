class HearingAppealStreamSnapshots < ActiveRecord::Migration
  def change
    create_table :hearing_appeal_stream_snapshots, id: false do |t|
      t.integer  :hearing_id
      t.integer  :appeal_id

      t.datetime :created_at, null: false
    end
  end
end
