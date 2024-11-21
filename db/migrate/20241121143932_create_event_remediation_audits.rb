class CreateEventRemediationAudits < ActiveRecord::Migration[6.1]
  def change
    create_table :event_remediation_audits, comment: "Stores records that are updated by the PersonAndVeteranEventRemediationJob" do |t|
      t.datetime :created_at, null: false, comment: "Automatic timestamp when row was created"
      t.integer :event_record_id, null: false, comment: "ID of the EventRecord that created or updated this record."
      t.bigint :remediated_record_id, null: false
      t.string :remediated_record_type, null: false
      t.jsonb :info, default: {}, comment: "Additional information about the remediation event"
      t.datetime :updated_at, null: false, comment: "Automatic timestamp whenever the record changes"

      # Add an index on remediated_record_type and remediated_record_id for fast lookups
      t.index [:remediated_record_type, :remediated_record_id], name: "index_event_remediation_audit_on_remediated_record"
      t.index ["info"], name: "index_event_remediation_audits_on_info", using: :gin
    end
  end
end
