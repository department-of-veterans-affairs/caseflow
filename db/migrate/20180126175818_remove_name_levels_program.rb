class RemoveNameLevelsProgram < ActiveRecord::Migration
  def change
    remove_column :worksheet_issues, :program
    remove_column :worksheet_issues, :name
    remove_column :worksheet_issues, :levels
  end
end
