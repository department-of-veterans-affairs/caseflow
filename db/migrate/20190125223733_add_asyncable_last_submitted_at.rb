class AddAsyncableLastSubmittedAt < ActiveRecord::Migration[5.1]
  def change
    [
      :request_issues,
      :board_grant_effectuations,
      :decision_documents,
      :request_issues_updates,
      :task_timers,
      :appeals,
      :supplemental_claims,
      :higher_level_reviews
    ].each do |tbl|
      add_column tbl, :last_submitted_at, :datetime
    end
  end
end
