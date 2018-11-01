class AddRatingIssuesParticipantNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:rating_issues, :participant_id, false, 0)
  end
end
