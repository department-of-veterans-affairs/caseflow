class AddUserRefToAnnotations < ActiveRecord::Migration[5.1]
  def change
    add_reference :annotations, :user, index: true, foreign_key: true
  end
end
