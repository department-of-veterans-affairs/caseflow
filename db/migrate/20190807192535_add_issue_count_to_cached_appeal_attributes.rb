class AddIssueCountToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :issue_count, :integer, comment: "Number of request issues for the appeal. Excludes decided issues on legacy appeals"
  end
end
