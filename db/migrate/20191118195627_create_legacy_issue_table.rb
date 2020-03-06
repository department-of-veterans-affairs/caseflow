class CreateLegacyIssueTable < ActiveRecord::Migration[5.1]
  def change
    create_table :legacy_issues, comment: "On an AMA decision review, when a veteran requests to review an issue that is already being contested on a legacy appeal, the legacy issue is connected to the request issue. If the veteran also chooses to opt their legacy issues into AMA and the issue is eligible to be transferred to AMA, the issues are closed in VACOLS through a legacy issue opt-in. This table stores the legacy issues connected to each request issue, and the record for opting them into AMA (if applicable)." do |t|
      t.belongs_to :request_issue, null: false, comment: "The request issue the legacy issue is being connected to."
      t.string :vacols_id, null: false, comment: "The VACOLS ID of the legacy appeal that the legacy issue is part of."
      t.integer :vacols_sequence_id, null: false, comment: "The sequence ID of the legacy issue on the legacy appeal. The vacols_id and vacols_sequence_id form a composite key to identify a specific legacy issue."
      t.timestamps null: false, comment: "Default created_at/updated_at"
    end
  end
end
