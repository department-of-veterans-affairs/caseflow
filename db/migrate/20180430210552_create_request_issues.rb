class CreateRequestIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :request_issues do |t|
      t.belongs_to :review_request, polymorphic: true, null: false, index: {name: "index_request_issues_on_review_request"}
      t.string     :rating_issue_reference_id, null: false
      t.date       :rating_issue_profile_date, null: false
      t.string     :contention_reference_id
      t.string     :description, null: false
    end
  end
end
