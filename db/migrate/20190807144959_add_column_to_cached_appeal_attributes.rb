class AddColumnToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :case_type, :string
    add_column :cached_appeal_attributes, :is_aod, :bool
  end
end
