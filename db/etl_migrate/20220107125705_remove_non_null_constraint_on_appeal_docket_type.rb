class RemoveNonNullConstraintOnAppealDocketType < Caseflow::Migration
  def up
    change_column_null :appeals, :docket_type, true
  end

  def down
    change_column_null :appeals, :docket_type, false
  end
end
