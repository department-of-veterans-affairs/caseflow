class AddAodToAppeals < ActiveRecord::Migration
  def change
    add_column :appeals, :aod, :boolean
  end
end
