class AddAppealToAdvanceOnDocketMotions < ActiveRecord::Migration[5.2]
  def change
    add_column :advance_on_docket_motions, :appeal_type, :string, comment: "The type of appeal this motion is associated with"
    add_column :advance_on_docket_motions, :appeal_id, :integer, comment: "The ID of the appeal this motion is associated with"
  end
end
