class AddCommentsToRampClosedAppeal < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:ramp_closed_appeals, "Keeps track of legacy appeals that are closed or partially closed in VACOLS due to being transitioned to a RAMP election.  This data can be used to rollback the RAMP Election if needed.")
    change_column_comment(:ramp_closed_appeals, :closed_on, "The date that the legacy appeal was closed in VACOLS and opted into RAMP.")
    change_column_comment(:ramp_closed_appeals, :nod_date, "The date when the Veteran filed a notice of disagreement for the original claims decision in the legacy system - the step before a Veteran receives a Statement of the Case and before they file a Form 9.")
    change_column_comment(:ramp_closed_appeals, :partial_closure_issue_sequence_ids, "If the entire legacy appeal could not be closed and moved to the RAMP Election, the VACOLS sequence IDs of issues on the legacy appeal which were closed are stored here, indicating that it was a partial closure.")
    change_column_comment(:ramp_closed_appeals, :ramp_election_id, "The ID of the RAMP election that closed the legacy appeal.")
    change_column_comment(:ramp_closed_appeals, :vacols_id, "The VACOLS ID of the legacy appeal that has been closed and opted into RAMP.")
  end
end
