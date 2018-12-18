class RenameTitleToActionInTasks < ActiveRecord::Migration[5.1]
  def change
  	rename_column :tasks, :title, :action
  end
end
