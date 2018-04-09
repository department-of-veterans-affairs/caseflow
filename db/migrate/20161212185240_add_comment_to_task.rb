class AddCommentToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :comment, :string
  end
end
