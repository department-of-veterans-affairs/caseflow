class AddOriginalLegacyAppealToLegacyIssueOptins < ActiveRecord::Migration[5.2]
  def change
    add_column :legacy_issue_optins, :original_legacy_appeal_disposition_code, :string, comment: "The original disposition code of legacy appeal being opted in"
    add_column :legacy_issue_optins, :original_legacy_appeal_decision_date, :date, comment: "The original disposition date of a legacy appeal being opted in"
    add_column :legacy_issue_optins, :folder_date_time_of_decision, :datetime, comment: "Date/Time of decision"
  end
end
