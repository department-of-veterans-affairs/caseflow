class AllowNilReviewOnRequestIssues < ActiveRecord::Migration[5.1]
  def change
    change_column_null :request_issues, :review_request_id, true
    change_column_null :request_issues, :review_request_type, true
  end
end
