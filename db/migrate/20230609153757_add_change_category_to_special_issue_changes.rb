class AddChangeCategoryToSpecialIssueChanges < ActiveRecord::Migration[5.2]
  def change
    add_column :special_issue_changes, :change_category, :string, null: false, comment: "Type of change that occured to the issue (Established Issue, Added Issue, Edited Issue, Removed Issue)"
  end
end
