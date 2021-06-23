# frozen_string_literal: true

class ValidateNewForeignKeysOnCavcRemandsTable < Caseflow::Migration
  def change
    validate_foreign_key "cavc_remands", column: "remand_appeal_id"
    validate_foreign_key "cavc_remands", column: "source_appeal_id"
  end
end
