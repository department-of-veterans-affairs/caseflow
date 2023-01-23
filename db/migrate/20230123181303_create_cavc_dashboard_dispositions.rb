class CreateCavcDashboardDispositions < Caseflow::Migration
  def change
    create_table :cavc_dashboard_dispositions do |t|
      t.bigint :cavc_remand_id, comment: "ID of the associated CAVC remand"
      t.bigint :request_issue_id, comment: "ID for a request issue that was filed with the CAVC Remand"
      t.bigint :cavc_dashboard_issue_id, commment: "ID for an issue that was added in the CAVC Dashboard"
      t.string :disposition, default: "N/A", null: false, comment: "The disposition of the issue"
      t.bigint :created_by_id, comment: "The ID for the user that created the record"
      t.bigint :updated_by_id, comment: "The ID for the user that most recently changed the record"
      t.timestamps
    end

    add_foreign_key "cavc_dashboard_dispositions", "cavc_remands", validate: false

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<-SQL
            ALTER TABLE cavc_dashboard_dispositions
              ADD CONSTRAINT single_issue_id
                CHECK (request_issue_id IS NULL OR cavc_dashboard_issue_id IS NULL)
          SQL
        end
      end

      dir.down do
        safety_assured do
          execute <<-SQL
            ALTER TABLE cavc_dashboard_dispositions
              DROP CONSTRAINT single_issue_id
          SQL
        end
      end
    end

    validate_foreign_key "cavc_dashboard_dispositions", "cavc_remands"
  end
end
