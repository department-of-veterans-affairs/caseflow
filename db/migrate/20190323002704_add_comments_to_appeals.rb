class AddCommentsToAppeals < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:appeals, "A table for the Decision Reviews intaken for Appeals to the Board (also known as a Notice of Disagreement).")

    change_column_comment(:appeals, :closest_regional_office, "The code for the regional office closest to the Veteran on the Appeal.")

    change_column_comment(:appeals, :docket_type, "The docket type selected by the Veteran on their Appeal form, which can be Hearing, Evidence Submission, or Direct Review.")

    change_column_comment(:appeals, :established_at, "Timestamp for when the Appeal has successfully been intaken into Caseflow.")

    change_column_comment(:appeals, :establishment_attempted_at, "Timestamp for when the Appeal's establishment was last attempted.")

    change_column_comment(:appeals, :establishment_error, "Not used, due to Appeal establishment not being asynchronous.")

    change_column_comment(:appeals, :establishment_last_submitted_at, "Timestamp for when the the job is eligible to run (can be reset to restart the job).")

    change_column_comment(:appeals, :establishment_processed_at, "Timestamp for when the establishment has succeeded in processing.")

    change_column_comment(:appeals, :establishment_submitted_at, "Timestamp for when an intake for a Decision Review finished being intaken by a Claim Assistant.")

    change_column_comment(:appeals, :legacy_opt_in_approved, "Selected by the Claims Assistant during intake.  Indicates whether a Veteran opted to withdraw their matching issues from the legacy process when submitting them for an AMA Decision Review. If there is a matching legacy issue, and it is not withdrawn, then it is ineligible for the AMA Decision Review.")

    change_column_comment(:appeals, :receipt_date, "The date that an Appeal form was received by central mail. This is used to determine which issues are within the timeliness window to be appealed. Only issues decided prior to the receipt date will show up as contestable issues. ")

    change_column_comment(:appeals, :target_decision_date, "If the Appeal docket is direct review, sets the target decision date for the Appeal, which is one year after the receipt_date.")

    change_column_comment(:appeals, :uuid, "The universally unique identifier for the appeal, which can be used to navigate to appeals/appeal_uuid")

    change_column_comment(:appeals, :veteran_file_number, "The file number of the Veteran that the Appeal is for.")

    change_column_comment(:appeals, :veteran_is_not_claimant, "Selected by the Claims Assistant during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else like a spouse or a child. Must be TRUE if Veteran is deceased.")
  end
end
