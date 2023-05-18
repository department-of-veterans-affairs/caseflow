class AdjustCommentToIncludeHcp < ActiveRecord::Migration[5.2]
  def change
    change_column_comment :unrecognized_appellants, :relationship, "Relationship to veteran. Allowed values: attorney, child, spouse, other, or healthcare_provider."
  end
end
