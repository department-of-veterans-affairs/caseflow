class AddAppealIndexToAodMotions < Caseflow::Migration
  def change
    add_safe_index :advance_on_docket_motions, ["appeal_type", "appeal_id"], name: "index_aod_motion_on_appeal_id_and_appeal_type"
  end
end
