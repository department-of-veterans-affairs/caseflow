class AddAsyncCanceledAt < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :establishment_canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :higher_level_reviews, :establishment_canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :supplemental_claims, :establishment_canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :board_grant_effectuations, :decision_sync_canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :request_issues, :decision_sync_canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :request_issues_updates, :canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :decision_documents, :canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :task_timers, :canceled_at, :datetime, comment: "Timestamp when job was abandoned"
    add_column :vbms_uploaded_documents, :canceled_at, :datetime, comment: "Timestamp when job was abandoned"
  end
end
