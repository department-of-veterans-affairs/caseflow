class CreateAppealSeries < ActiveRecord::Migration
  def change
    create_table :appeal_series do |t|
      t.boolean :incomplete, default: false
      t.integer :merged_appeal_count
    end
  end
end
