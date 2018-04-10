class RemoveNullConstraintOnContentionReferenceId < ActiveRecord::Migration[5.1]
  def change
    change_column_null :ramp_issues, :contention_reference_id, true
  end
end
