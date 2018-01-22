class CreateDocketTracers < ActiveRecord::Migration
  def change
    create_table :docket_tracers do |t|
      t.belongs_to :docket_snapshot
      t.date       :month
      t.integer    :ahead_count
      t.integer    :ahead_and_ready_count
    end

    add_index(:docket_tracers, [:docket_snapshot_id, :month], unique: true)
  end
end
