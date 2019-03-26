class AddUndoDedupToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :undo_record_merging, :jsonb
  end
end
