class AddNullConstraintToAnnotationComments < ActiveRecord::Migration[5.1]
  def change
    change_column_null :annotations, :comment, false, ''
  end
end
