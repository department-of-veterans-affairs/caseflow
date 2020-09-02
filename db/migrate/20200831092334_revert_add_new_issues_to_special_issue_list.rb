class RevertAddNewIssuesToSpecialIssueList < ActiveRecord::Migration[5.2]
  def up
    safety_assured { remove_column :special_issue_lists, :burn_pit }
    safety_assured { remove_column :special_issue_lists, :military_sexual_trauma }
    safety_assured { remove_column :special_issue_lists, :blue_water }
    safety_assured { remove_column :special_issue_lists, :no_special_issues }
    safety_assured { remove_column :special_issue_lists, :us_court_of_appeals_for_veterans_claims }
  end

  def down
    add_column :special_issue_lists, :burn_pit, :boolean, comment: "Burn Pit"
    add_column :special_issue_lists, :military_sexual_trauma, :boolean, comment: "Military Sexual Trauma (MST)"
    add_column :special_issue_lists, :blue_water, :boolean, comment: "Blue Water"
    add_column :special_issue_lists, :us_court_of_appeals_for_veterans_claims, :boolean, comment: "US Court of Appeals for Veterans Claims (CAVC)"
    add_column :special_issue_lists, :no_special_issues, :boolean, comment: "Affirmative no special issues, added belatedly"
    change_column_default :special_issue_lists, :burn_pit, false
    change_column_default :special_issue_lists, :military_sexual_trauma, false
    change_column_default :special_issue_lists, :blue_water, false
    change_column_default :special_issue_lists, :us_court_of_appeals_for_veterans_claims, false
    change_column_default :special_issue_lists, :no_special_issues, false
  end
end
