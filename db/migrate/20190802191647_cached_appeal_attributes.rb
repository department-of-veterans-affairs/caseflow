class CachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :docket_name, :string
  end
end
