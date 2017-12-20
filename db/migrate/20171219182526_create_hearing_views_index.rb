class CreateHearingViewsIndex < ActiveRecord::Migration
  def change
    safety_assured { add_index(:hearing_views, [:hearing_id, :user_id], unique: true) }
  end
end
