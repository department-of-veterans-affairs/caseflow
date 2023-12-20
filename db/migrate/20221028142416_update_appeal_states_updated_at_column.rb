class UpdateAppealStatesUpdatedAtColumn < Caseflow::Migration
  # Purpose: Method to update the appeal_state.updated_at column to be nullable
  # when this migration is applied
  #
  # Params: None
  #
  # Returns: None
  def up
    change_column_null :appeal_states, :updated_at, true
  end

  # Purpose: Method to update the appeal_state.updated_at column to not be nullable
  # when this migration is rollbacked
  #
  # Params: None
  #
  # Returns: None
  def down
    change_column_null :appeal_states, :updated_at, false
  end
end
