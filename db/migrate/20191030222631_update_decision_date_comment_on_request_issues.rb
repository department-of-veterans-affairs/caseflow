class UpdateDecisionDateCommentOnRequestIssues < ActiveRecord::Migration[5.1]
  def change
  	change_column_comment(:request_issues, :decision_date, "Either the rating issue's promulgation date, the decision issue's approx decision date or unidentified decision date entered by the user")
  end
end
