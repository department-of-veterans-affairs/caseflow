class RemoveUndoColumnFromUser < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :user, :undo_record_merging }
  end
end
