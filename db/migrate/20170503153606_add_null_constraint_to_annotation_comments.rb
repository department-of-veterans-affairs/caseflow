class AddNullConstraintToAnnotationComments < ActiveRecord::Migration
  def change
    change_column_null :annotations, :comment, false, ''
  end
end
