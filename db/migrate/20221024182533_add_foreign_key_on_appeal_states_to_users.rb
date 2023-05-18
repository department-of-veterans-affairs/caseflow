class AddForeignKeyOnAppealStatesToUsers < Caseflow::Migration
  def change
    add_foreign_key :appeal_states, :users, column: "updated_by_id", validate: false
    add_foreign_key :appeal_states, :users, column: "created_by_id", validate: false
  end
end