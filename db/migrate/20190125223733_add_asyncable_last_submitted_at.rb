class AddAsyncableLastSubmittedAt < ActiveRecord::Migration[5.1]
  def asyncable_tables
    [
      :request_issues,
      :board_grant_effectuations,
      :decision_documents,
      :request_issues_updates,
      :task_timers,
      :appeals,
      :supplemental_claims,
      :higher_level_reviews
    ]
  end

  def up
    asyncable_tables.each do |tbl|
      safety_assured do
        submitted_at_column = tbl.to_s.classify.constantize.submitted_at_column
        add_column tbl, :last_submitted_at, :datetime
        execute "UPDATE #{tbl} SET last_submitted_at=#{submitted_at_column}"
      end
    end
  end

  def down
    asyncable_tables.each do |tbl|
      remove_column tbl, :last_submitted_at
    end
  end
end
