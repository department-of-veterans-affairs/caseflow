class AddIntakeDatabaseComments < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:appeals, "Decision reviews intaken for AMA appeals to the board (also known as a notice of disagreement).")

    change_table_comment(:decision_issues, "Issues that represent a decision made on a decision review's request issue.")

    change_table_comment(:end_product_establishments, "Represents end products that have been, or need to be established by Caseflow. Used to track the status of those end products as they are processed in VBMS and/or SHARE.")

    change_table_comment(:ramp_refilings, "Intake data for RAMP refilings, also known as RAMP selection.")

    change_table_comment(:request_issues_updates, "Keeps track of edits to request issues on a decision review that happen after the initial intake, such as removing and adding issues.  When the decision review is processed in VBMS, this also tracks whether adding or removing contentions in VBMS for the update has succeeded.")

    change_table_comment(:request_decision_issues, "Bridge table to match request issues to decision issues.")

    change_table_comment(:ramp_elections, "Intake data for RAMP elections.")

    change_table_comment(:intakes, "Represents the intake of an form or request made by a veteran.")

    change_table_comment(:decision_issues, "Issues that represent a decision made on a request issue.")

    change_column_comment(:decision_issues, :benefit_type, "Classification of the benefit being decided on. Maps 1 to 1 to VA lines of business, and typically used to know which line of business the decision correlates to.")

    change_column_comment(:decision_issues, :caseflow_decision_date, "This is a decision date for decision issues where decisions are entered in Caseflow, such as for appeals or for decision reviews with a business line that is not processed in VBMS.")

     change_column_comment(:decision_issues, :created_at, "Automatic timestamp when row was created.")

     change_column_comment(:decision_issues, :decision_review_id, "ID of the decision review the decision was made on.")

     change_column_comment(:decision_issues, :decision_review_type, "Type of the decision review the decision was made on.")

     change_column_comment(:decision_issues, :decision_text, "If decision resulted in a change to a rating, the rating issue's decision text.")

     change_column_comment(:decision_issues, :description, "Optional description that the user can input for decisions made in Caseflow.")

     change_column_comment(:decision_issues, :diagnostic_code, "If a decision resulted in a rating, this is the rating issue's diagnostic code.")

     change_column_comment(:decision_issues, :disposition, "The disposition for a decision issue. Dispositions made in Caseflow and dispositions made in VBMS can have different values.")

     change_column_comment(:decision_issues, :end_product_last_action_date, "After an end product gets synced with a status of CLR (cleared), the end product's last_action_date is saved on any decision issues that are created as a result. This is used as a proxy for decision date for non-rating issues that are processed in VBMS because they don't have a rating profile date, and the exact decision date is not available.")

     change_column_comment(:decision_issues, :participant_id, "The Veteran's participant id.")

     change_column_comment(:decision_issues, :profile_date, "The profile date of the rating that a decision issue resulted in (if applicable). The profile_date is used as an identifier for the rating, and is the date that most closely maps to what the Veteran writes down as the decision date.")

     change_column_comment(:decision_issues, :promulgation_date, "The promulgation date of the rating that a decision issue resulted in (if applicable). It is used for calculating whether a decision issue is within the timeliness window to be appealed or get a higher level review.")

     change_column_comment(:decision_issues, :rating_issue_reference_id, "Identifies the specific issue on the rating that resulted from the decision issue (a rating can have multiple issues). This is unique per rating issue.")

     change_column_comment(:appeals, :closest_regional_office, "The code for the regional office closest to the Veteran on the appeal.")

     change_column_comment(:appeals, :docket_type, "The docket type selected by the Veteran on their appeal form, which can be hearing, evidence submission, or direct review.")

     change_column_comment(:appeals, :established_at, "Timestamp for when the appeal has successfully been intaken into Caseflow.")

     change_column_comment(:appeals, :establishment_attempted_at, "Timestamp for when the appeal's establishment was last attempted.")

     change_column_comment(:appeals, :establishment_error, "The error message if attempting to establish the appeal resulted in an error. This gets cleared once the establishment is successful.")

     change_column_comment(:appeals, :establishment_last_submitted_at, "Timestamp for when the the job is eligible to run (can be reset to restart the job).")

     change_column_comment(:appeals, :establishment_processed_at, "Timestamp for when the establishment has succeeded in processing.")

     change_column_comment(:appeals, :establishment_submitted_at, "Timestamp for when the intake was submitted by the user.")

     change_column_comment(:appeals, :legacy_opt_in_approved, "Indicates whether a Veteran opted to withdraw their matching issues from the legacy process when submitting them for an decision review. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review.")

     change_column_comment(:appeals, :receipt_date, "The date that an appeal form was received by central mail. Used to determine which issues are within the timeliness window to be appealed. Only issues decided prior to the receipt date will show up as contestable issues.")

     change_column_comment(:appeals, :target_decision_date, "If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date.")

     change_column_comment(:appeals, :uuid, "The universally unique identifier for the appeal, which can be used to navigate to appeals/appeal_uuid")

     change_column_comment(:appeals, :veteran_file_number, "The file number of the Veteran for this review. Not unique per Veteran.")

     change_column_comment(:appeals, :veteran_is_not_claimant, "Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased.")

     change_column_comment(:ramp_refilings, :appeal_docket, "When the RAMP refiling option selected is appeal, they can select hearing, direct review or evidence submission as the appeal docket.")

     change_column_comment(:ramp_refilings, :established_at, "Timestamp for when the review successfully established, including any related actions such as establishing a claim in VBMS if applicable.")

     change_column_comment(:ramp_refilings, :establishment_processed_at, "Timestamp for when the end product establishments for the RAMP review finished processing.")

     change_column_comment(:ramp_refilings, :establishment_submitted_at, "Timestamp for when an intake for a review was submitted by the user.")

     change_column_comment(:ramp_refilings, :has_ineligible_issue, "Selected by the user during intake, indicates whether the Veteran has ineligible issues.")

     change_column_comment(:ramp_refilings, :option_selected, "Which lane the RAMP refiling is for, between appeal, higher level review, and supplemental claim.")

     change_column_comment(:ramp_refilings, :receipt_date, "The date that the RAMP form was received by central mail.")

     change_column_comment(:ramp_refilings, :veteran_file_number, "The file number of the Veteran for this review. Not unique per Veteran.")

     change_column_comment(:request_issues_updates, :after_request_issue_ids, "An array of the request issue IDs after a user has finished editing a decision review. Used with before_request_issue_ids to determine appropriate actions (such as which contentions need to be added).")

     change_column_comment(:request_issues_updates, :attempted_at, "Timestamp for when the request issue update was last attempted.")

     change_column_comment(:request_issues_updates, :before_request_issue_ids, "An array of the request issue IDs previously on the decision review before this editing session. Used with after_request_issue_ids to determine appropriate actions (such as which contentions need to be removed).")

     change_column_comment(:request_issues_updates, :error, "The error message if the last attempt at updating the request issues was not successful.")

     change_column_comment(:request_issues_updates, :last_submitted_at, "Timestamp for when the the job is eligible to run (can be reset to restart the job).")

     change_column_comment(:request_issues_updates, :processed_at, "Timestamp for when the request issue updated successfully completed processing.")

     change_column_comment(:request_issues_updates, :review_id, "The ID of the decision review edited.")

     change_column_comment(:request_issues_updates, :review_type, "The type of the decision review edited.")

     change_column_comment(:request_issues_updates, :submitted_at, "Timestamp when the edit was originally submitted.")

     change_column_comment(:request_issues_updates, :user_id, "The ID of the user who edited the decision review.")

     change_column_comment(:request_decision_issues, :created_at, "Automatic timestamp when row was created.")

     change_column_comment(:request_decision_issues, :decision_issue_id, "The ID of the decision issue.")

     change_column_comment(:request_decision_issues, :request_issue_id, "The ID of the request issue.")

     change_column_comment(:request_decision_issues, :updated_at, "Automatically populated when the record is updated.")

     change_column_comment(:ramp_elections, :established_at, "Timestamp for when the review successfully established, including any related actions such as establishing a claim in VBMS if applicable.")

     change_column_comment(:ramp_elections, :notice_date, "The date that the Veteran was notified of their option to opt their legacy appeals into RAMP.")

     change_column_comment(:ramp_elections, :option_selected, "Indicates whether the Veteran selected for their RAMP election to be processed as a higher level review (with or without a hearing), a supplemental claim, or a board appeal.")

     change_column_comment(:ramp_elections, :receipt_date, "The date that the RAMP form was received by central mail.")

     change_column_comment(:ramp_elections, :veteran_file_number, "The file number of the Veteran for this review. Not unique per Veteran.")

     change_column_comment(:intakes, :cancel_other, "Notes added if a user canceled an intake for any reason other than the stock set of options.")

     change_column_comment(:intakes, :cancel_reason, "The reason the intake was canceled. Could have been manually canceled by a user, or automatic.")

     change_column_comment(:intakes, :completed_at, "Timestamp for when the intake was completed, whether it was successful or not.")

     change_column_comment(:intakes, :completion_started_at, "Timestamp for when the user submitted the intake to be completed.")

     change_column_comment(:intakes, :completion_status, "Indicates whether the intake was successful, or was closed by being canceled, expired, or due to an error.")

     change_column_comment(:intakes, :detail_id, "The ID of the decision review or RAMP review that resulted from the intake.")

     change_column_comment(:intakes, :detail_type, "The type of decision review or RAMP review that the intake resulted in.")

     change_column_comment(:intakes, :error_code, "If the intake was unsuccessful due to a set of known errors, the error code is stored here. An error is also stored here for RAMP elections that are connected to an active end product, even though the intake is a success.")

     change_column_comment(:intakes, :started_at, "Timestamp for when the intake was created, which happens when a user successfully searches for a Veteran.")

     change_column_comment(:intakes, :type, "The class name of the intake.")

     change_column_comment(:intakes, :user_id, "The ID of the user who created the intake.")

     change_column_comment(:intakes, :veteran_file_number, "The file number of the Veteran which the intake is for. Not unique per Veteran.")

     change_column_comment(:end_product_establishments, :benefit_type_code, "1 if the Veteran is alive, and 2 if the Veteran is deceased. Not to be confused with benefit_type, which is unrelated.")

     change_column_comment(:end_product_establishments, :claim_date, "The claim_date for end products established is set to the receipt date of the form.")

     change_column_comment(:end_product_establishments, :claimant_participant_id, "The participant ID of the claimant submitted on the end product.")

     change_column_comment(:end_product_establishments, :code, "The end product code, which determines the type of end product that is established. For example, it can contain information about whether it is rating, nonrating, compensation, pension, created automatically due to a Duty to Assist Error, and more.")

     change_column_comment(:end_product_establishments, :committed_at, "Timestamp indicating other actions performed as part of a larger atomic operation containing the end product establishment, such as creating contentions, are also complete.")

     change_column_comment(:end_product_establishments, :development_item_reference_id, "When a Veteran requests an informal conference with their higher level review, a tracked item is created. This stores the ID of the of the tracked item, it is also used to indicate the success of creating the tracked item.")

     change_column_comment(:end_product_establishments, :doc_reference_id, "When a Veteran requests an informal conference, a claimant letter is generated. This stores the document ID of the claimant letter, and is also used to track the success of creating the claimant letter.")

     change_column_comment(:end_product_establishments, :established_at, "Timestamp for when the end product was established.")

     change_column_comment(:end_product_establishments, :last_synced_at, "The time that the status of the end product was last synced with BGS. The end product is synced until it is canceled or cleared, meaning it is no longer active.")

     change_column_comment(:end_product_establishments, :modifier, "The end product modifier. For higher level reviews, the modifiers range from 030-039. For supplemental claims, they range from 040-049. The same modifier cannot be used twice for an active end product per Veteran. Once an end product is no longer active, the modifier can be used again.")

     change_column_comment(:end_product_establishments, :payee_code, "The payee_code of the claimant submitted for this end product.")

     change_column_comment(:end_product_establishments, :reference_id, "The claim_id of the end product, which is stored after the end product is successfully established in VBMS.")

     change_column_comment(:end_product_establishments, :source_id, "The ID of the source that resulted in this end product establishment.")

     change_column_comment(:end_product_establishments, :source_type, "The type of source that resulted in this end product establishment.")

     change_column_comment(:end_product_establishments, :station, "The station ID of the end product's station.")

     change_column_comment(:end_product_establishments, :synced_status, "The status of the end product, which is synced by a job. Once and end product is cleared (CLR) or canceled (CAN) the status is final and the end product will not continue being synced.")

     change_column_comment(:end_product_establishments, :user_id, "The ID of the user who performed the decision review intake.")

     change_column_comment(:end_product_establishments, :veteran_file_number, "The file number of the Veteran submitted when establishing the end product.")
  end
end
