class AddCommentsToDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:decision_issues, "Issues that represent a decision made on a Decision Review's request_issue.")

    change_column_comment(:decision_issues, :benefit_type, "The Benefit Type, also known as the Line of Business for a decision issue. For example, compensation, pension, or education.")

    change_column_comment(:decision_issues, :caseflow_decision_date, "This is a decision date for decision issues where decisions are entered in Caseflow, such as for Appeals or for Decision Reviews with a business line that is not processed in VBMS.")

    change_column_comment(:decision_issues, :created_at, "Automatic timestamp when row was created")

    change_column_comment(:decision_issues, :decision_review_id, "The ID of the Decision Review with the Request Issue that was decided in order to create this Decision Issue.")

    change_column_comment(:decision_issues, :decision_review_type, "The type of the Decision Review with the Request Issue that was decided in order to create this Decision Issue.")

    change_column_comment(:decision_issues, :decision_text, "If decision issue is connected to a rating, this is the rating issue's decision text")

    change_column_comment(:decision_issues, :description, "Optional description that user can input")

    change_column_comment(:decision_issues, :diagnostic_code, "If decision issue is connected to a rating, this is the rating issue's diagnostic code")

    change_column_comment(:decision_issues, :disposition, "The disposition for a decision issue, for example 'granted' or 'denied'.")

    change_column_comment(:decision_issues, :end_product_last_action_date, "After an End Product gets synced with a status of CLR (cleared), we save the End Product's last_action_date on any Decision Issues that are created as a result. We use this as a proxy for decision date for non-rating issues that were processed in VBMS because they don't have a rating profile date, and we do not have access to the exact decision date.")

    change_column_comment(:decision_issues, :participant_id, "Veteran's participant id")

    change_column_comment(:decision_issues, :profile_date, "If a decision issue is connected to a rating, this is the profile_date of that rating. The profile_date is used as an identifier for the rating, and is the date we believe that the Veterans think of as the decision date.")

    change_column_comment(:decision_issues, :promulgation_date, "If a decision issue is connected to a rating, it will have a promulgation date. This represents the date that the decision is legally official. It is different than the decision date. It is used for calculating whether a decision issue is within the timeliness window to be appealed or get a higher level review.")

    change_column_comment(:decision_issues, :rating_issue_reference_id, "If the decision issue is connected to the rating, this ID identifies the specific issue on the rating that is connected to the decision issue (a rating can have multiple issues). This is unique per rating issue.")
  end
end
