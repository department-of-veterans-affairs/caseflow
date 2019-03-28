class RemoveUndoColumnFromUser < ActiveRecord::Migration[5.1]
  def change
    remove_column :undo_record_merging, :user
  end
end
