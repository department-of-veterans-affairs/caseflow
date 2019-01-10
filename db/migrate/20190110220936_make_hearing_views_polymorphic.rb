class MakeHearingViewsPolymorphic < ActiveRecord::Migration[5.1]
  def change
    add_column :hearing_views, :hearing_type, :string
  end
end
