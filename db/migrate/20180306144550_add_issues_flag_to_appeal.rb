class AddIssuesFlagToAppeal < ActiveRecord::Migration
  def change
    add_column :appeals, :issues_pulled, :boolean
  end
end
