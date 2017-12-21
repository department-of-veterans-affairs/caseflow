class CreateHearingViews < ActiveRecord::Migration
  def change
    create_table :hearing_views do |t|
      t.belongs_to :hearing, null: false
      t.belongs_to :user, null: false
      t.timestamps
    end
  end
end
