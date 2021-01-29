class RenameSpecialIssuesCavcColumn < ActiveRecord::Migration[5.2]
  def change
    safety_assured do 
      rename_column :special_issue_lists, :cavc, :us_court_of_appeals_for_veterans_claims
    end
  end
end
