class AddIssueCountToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :issue_count, :integer, comment: "Number of issues on the appeal."
  end
end
