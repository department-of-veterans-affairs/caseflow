class AddFieldsToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :program, :string
    add_column :issues, :name, :string
    add_column :issues, :levels, :string, array: true
    add_column :issues, :description, :string, array: true
    add_column :issues, :from_vacols, :boolean
  end
end
