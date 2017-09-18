class AddFieldsToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :program, :string
    add_column :issues, :name, :string
    add_column :issues, :levels, :string
    add_column :issues, :description, :string
    add_column :issues, :from_vacols, :boolean
  end
end
