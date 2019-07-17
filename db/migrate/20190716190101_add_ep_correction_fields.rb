class AddEpCorrectionFields < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :correction_claim_label, :string, null: true, comment: "EP 930 correction type. Allowed values: control, local_quality_team, national_quality_team where 'control' is a regular correction, 'local_quality_team' is processed by a local quality team, and 'national_quality_team' is processed by a national quality team. This is needed for EP 930."
    add_column :request_issues, :corrected_request_issue_id, :integer, null: true, comment: "The ID of the original incorrect request issue. This is needed for EP 930"
  end
end
