class RenameRatingFieldsInDecisionIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_issues, :rating_promulgation_date, :datetime, comment: "The promulgation date of the rating that a decision issue resulted in (if applicable). It is used for calculating whether a decision issue is within the timeliness window to be appealed or get a higher level review."
    add_column :decision_issues, :rating_profile_date, :datetime, comment: "The profile date of the rating that a decision issue resulted in (if applicable). The profile_date is used as an identifier for the rating, and is the date that most closely maps to what the Veteran writes down as the decision date."
  end
end
