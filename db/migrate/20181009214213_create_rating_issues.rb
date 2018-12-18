class CreateRatingIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :rating_issues do |t|
      t.belongs_to :request_issue, null: false, index: true
      t.string     :reference_id, null: false
      t.datetime   :profile_date, null: false
      t.string     :decision_text
    end
  end
end
