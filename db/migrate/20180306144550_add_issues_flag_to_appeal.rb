class AddIssuesFlagToAppeal < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :issues_pulled, :boolean
  end
end
