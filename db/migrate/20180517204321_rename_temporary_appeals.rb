class RenameTemporaryAppeals < ActiveRecord::Migration[5.1]
  def change
    rename_table :temporary_appeals, :appeals
  end
end
