class AddNewIssuesToSpecialIssueList < ActiveRecord::Migration[5.2]
  def up
    add_column :special_issue_lists, :burn_pit, :boolean, comment: "Burn Pit"
    add_column :special_issue_lists, :military_sexual_trauma, :boolean, comment: "Military Sexual Trauma (MST)"
    add_column :special_issue_lists, :blue_water, :boolean, comment: "Blue Water"
    add_column :special_issue_lists, :cavc, :boolean, comment: "US Court of Appeals for Veterans Claims (CAVC)"
    add_column :special_issue_lists, :no_special_issues, :boolean, comment: "Affirmative no special issues, added belatedly"
    change_column_default :special_issue_lists, :burn_pit, false
    change_column_default :special_issue_lists, :military_sexual_trauma, false
    change_column_default :special_issue_lists, :blue_water, false
    change_column_default :special_issue_lists, :cavc, false
    change_column_default :special_issue_lists, :no_special_issues, false
  end

  def down
    remove_column :special_issue_lists, :burn_pit
    remove_column :special_issue_lists, :military_sexual_trauma
    remove_column :special_issue_lists, :blue_water
    remove_column :special_issue_lists, :cavc
    remove_column :special_issue_lists, :no_special_issues
  end
end
