class MakeAppealViewPolymorphic < ActiveRecord::Migration[5.1]
  def change
    add_column :appeal_views, :appeal_type, :string
  end
end
