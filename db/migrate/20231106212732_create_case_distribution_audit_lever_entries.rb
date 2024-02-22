class CreateCaseDistributionAuditLeverEntries < Caseflow::Migration
  def change
    create_table :case_distribution_audit_lever_entries, comment:"A generalized table for Case Distribution audit lever records within caseflow" do |t|
      t.references :user, foreign_key: true, null: true, comment:"Indicates the id of the user who perfomed the action"
      t.references :case_distribution_lever, foreign_key: true, null: false, comment:"Indicates the Case Distriubution levers id", index: { name: 'index_cd_audit_lever_entries_on_cd_lever_id' }
      t.string :user_name, null: false, comment:"Indicates the Username"
      t.string :title, null: false, comment:"Indicates the title to maintain the history"
      t.string :previous_value, null: true, comment:"Indicates the previous value of the column"
      t.string :update_value, null: true, comment:"Indicates the updated value of the column"
      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
