class RemoveNullConstraintOnContentionReferenceId < ActiveRecord::Migration
  def change
    change_column_null :ramp_issues, :contention_reference_id, true
  end
end
