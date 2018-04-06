class CreateDocketTracers < ActiveRecord::Migration[5.1]
  def change
    create_table :docket_tracers do |t|
      t.belongs_to :docket_snapshot
      t.date       :month
      t.integer    :ahead_count
      t.integer    :ahead_and_ready_count
    end
  end
end
