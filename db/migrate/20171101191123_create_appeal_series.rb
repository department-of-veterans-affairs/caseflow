class CreateAppealSeries < ActiveRecord::Migration
  def change
    create_table :appeal_series do |t|
      t.boolean :incomplete
      t.integer :merged_appeal_count
    end
  end
end
