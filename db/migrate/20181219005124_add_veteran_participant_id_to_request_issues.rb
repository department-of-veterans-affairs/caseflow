class AddVeteranParticipantIdToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :veteran_participant_id, :string
  end
end
