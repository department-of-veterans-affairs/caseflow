class UpdateDecisionDateCommentOnRequestIssues < ActiveRecord::Migration[5.1]
  def change
  	change_column_comment(:request_issues, :decision_date, "Either the rating issue's promulgation date, the decision issue's approx decision date or the decision date entered by the user (for nonrating and unidentified issues)")
  end
end
