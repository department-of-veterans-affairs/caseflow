class CreateAppealSeries < ActiveRecord::Migration
  def change
    create_table :appeal_series do |t|
      t.boolean :incomplete
    end
  end
end
