# frozen_string_literal: true

class RemoveNonNullConstraintOnAppealReceiptDate < Caseflow::Migration
  def up
    change_column_null :appeals, :receipt_date, true
  end

  def down
    change_column_null :appeals, :receipt_date, false
  end
end
