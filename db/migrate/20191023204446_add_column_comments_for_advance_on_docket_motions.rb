class AddColumnCommentsForAdvanceOnDocketMotions < ActiveRecord::Migration[5.1]
  def change
    change_column_comment(:advance_on_docket_motions, :granted, "Whether VLJ has determined that there is sufficient cause to fast-track an appeal, i.e. grant or deny the motion to AOD.")
    change_column_comment(:advance_on_docket_motions, :person_id, "Appellant ID")
    change_column_comment(:advance_on_docket_motions, :reason, "VLJ's rationale for their decision on motion to AOD.")
  end
end
