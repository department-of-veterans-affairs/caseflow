class ChangeDecisionIssueParticipantIdToString < ActiveRecord::Migration[5.1]
  def change
    change_column :decision_issues, :participant_id, :string
  end
end
