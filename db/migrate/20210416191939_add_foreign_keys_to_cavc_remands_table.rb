# frozen_string_literal: true

class AddForeignKeysToCavcRemandsTable < Caseflow::Migration
  def change
    add_foreign_key "cavc_remands", "appeals", column: "remand_appeal_id", validate: false
    add_foreign_key "cavc_remands", "appeals", column: "source_appeal_id", validate: false
  end
end
