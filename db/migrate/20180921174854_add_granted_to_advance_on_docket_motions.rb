class AddGrantedToAdvanceOnDocketMotions < ActiveRecord::Migration[5.1]
  def change
    add_column :advance_on_docket_grants, :granted, :boolean
    rename_table :advance_on_docket_grants, :advance_on_docket_motions
  end
end
