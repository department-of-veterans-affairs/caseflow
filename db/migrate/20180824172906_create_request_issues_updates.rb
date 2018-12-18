class CreateRequestIssuesUpdates < ActiveRecord::Migration[5.1]
  def change
    create_table :request_issues_updates do |t|
      t.belongs_to :user, null: false
      t.belongs_to :review, polymorphic: true, null: false
      t.integer :before_request_issue_ids, array: true, null: false
      t.integer :after_request_issue_ids, array: true, null: false
      t.datetime :processed_at
    end
  end
end
