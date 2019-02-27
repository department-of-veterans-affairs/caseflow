class AddCommentsForLegacyIssueOptin < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:legacy_issue_optins, "When a VACOLS issue from a legacy appeal is opted-in to AMA, this table keeps track of the related request_issue, and the status of processing the opt-in, or rollback if the request issue is removed from a Decision Review.")
    change_column_comment(:legacy_issue_optins, :created_at, "When a Request Issue is connected to a VACOLS issue on a legacy appeal, and the Veteran has agreed to withdraw their legacy appeals, a legacy_issue_optin is created at the time the Decision Review is successfully intaken. This is used to indicate that the legacy issue should subsequently be opted into AMA in VACOLS. ")
    change_column_comment(:legacy_issue_optins, :optin_processed_at, "The timestamp for when the opt-in was successfully processed, meaning it was updated in VACOLS as opted into AMA.")
    change_column_comment(:legacy_issue_optins, :original_disposition_code, "The original disposition code of the VACOLS issue being opted in. Stored in case the opt-in is rolled back.")
    change_column_comment(:legacy_issue_optins, :original_disposition_date, "The original disposition date of the VACOLS issue being opted in. Stored in case the opt-in is rolled back.")
    change_column_comment(:legacy_issue_optins, :request_issue_id, "The request issue connected to the legacy VACOLS issue that has been opted in.")
    change_column_comment(:legacy_issue_optins, :rollback_created_at, "Timestamp for when the connected request issue is removed from a Decision Review during edit, indicating that the opt-in needs to be rolled back.")
    change_column_comment(:legacy_issue_optins, :rollback_processed_at, "Timestamp for when a rolled back opt-in has successfully finished being rolled back.")
    change_column_comment(:legacy_issue_optins, :updated_at, "Automatically populated when the record is updated.")
  end
end
