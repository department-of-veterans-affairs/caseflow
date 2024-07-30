class AddSubjectTextAndPercentNumberToDecisionIssue < ActiveRecord::Migration[5.2]
  def change
    add_column :decision_issues, :subject_text, :text, comment: "subject_text from RatingIssue (subjctTxt from Rating Profile)"
    add_column :decision_issues, :percent_number, :string, comment: "percent_number from RatingIssue (prcntNo from Rating Profile)"
  end
end
