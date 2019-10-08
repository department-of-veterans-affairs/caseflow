class AddEpCorrectionFields < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :correction_type, :string, null: true, comment: "EP 930 correction type. Allowed values: control, local_quality_error, national_quality_error where 'control' is a regular correction, 'local_quality_error' was found after the fact by a local quality review team, and 'national_quality_error' was similarly found by a national quality review team. This is needed for EP 930."
    add_column :request_issues, :corrected_by_request_issue_id, :integer, null: true, comment: "If this request issue has been corrected, the ID of the new correction request issue. This is needed for EP 930."
    add_column :request_issues_updates, :corrected_request_issue_ids, :integer, array: true, comment: 'An array of the request issue IDs that were corrected during this request issues update.'
  end
end
