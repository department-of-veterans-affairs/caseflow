class CreateLegacyIssueOptins < ActiveRecord::Migration[5.1]
  def change
    create_table :legacy_issue_optins do |t|
      t.belongs_to :review_request, polymorphic: true, null: false, index: { name: "idx_legacy_issue_optins_review_request" }
      t.belongs_to :request_issue, null: false
      t.timestamps null: false
      t.datetime :submitted_at
      t.datetime :attempted_at
      t.datetime :processed_at
      t.string :error
    end
  end
end
