class AddCommentsToRampElectionRollbacks < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:ramp_election_rollbacks, "If a RAMP election needs to get rolled back, for example if the EP is canceled, it is tracked here. Also any VACOLS issues that were closed in the legacy system and opted into RAMP are re-opened in the legacy system.")

    change_column_comment(:ramp_election_rollbacks, :created_at, "Timestamp for when the rollback was created.")

    change_column_comment(:ramp_election_rollbacks, :ramp_election_id, "The ID of the RAMP Election being rolled back.")

    change_column_comment(:ramp_election_rollbacks, :reason, "The reason for rolling back the RAMP Election. Rollbacks happen automatically for canceled RAMP Election End Products, but can also happen for other reason such as by request.")

    change_column_comment(:ramp_election_rollbacks, :reopened_vacols_ids, "The IDs of any legacy appeals which were reopened as a result of rolling back the RAMP Election, corresponding to the VACOLS BFKEY.")

    change_column_comment(:ramp_election_rollbacks, :updated_at, "Timestamp for when the rollback was last updated.")

    change_column_comment(:ramp_election_rollbacks, :user_id, "The user who created the RAMP Election rollback, typically a system user.")
  end
end
