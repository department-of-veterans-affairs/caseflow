class AddColumnToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :case_type, :string, comment: "The case type, i.e. original, post remand, CAVC remand, etc"
    add_column :cached_appeal_attributes, :is_aod, :bool, comment: "Whether the case is Advanced on Docket"
  end
end
