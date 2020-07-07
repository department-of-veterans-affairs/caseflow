class AddNewContensionsToLegacyAppeal < ActiveRecord::Migration[5.2]
  def up
    add_column :legacy_appeals, :burn_pit, :boolean, comment: "Burn Pit"
    add_column :legacy_appeals, :military_sexual_trauma, :boolean, comment: "Military Sexual Trauma (MST)"
    add_column :legacy_appeals, :blue_water, :boolean, comment: "Blue Water"
    add_column :legacy_appeals, :us_court_of_appeals_for_veterans_claims, :boolean, comment: "US Court of Appeals for Veterans Claims (CAVC)"
    add_column :legacy_appeals, :no_special_issues, :boolean, comment: "Affirmative no special issues; column added belatedly"
    change_column_default :legacy_appeals, :burn_pit, false
    change_column_default :legacy_appeals, :military_sexual_trauma, false
    change_column_default :legacy_appeals, :blue_water, false
    change_column_default :legacy_appeals, :us_court_of_appeals_for_veterans_claims, false
    change_column_default :legacy_appeals, :no_special_issues, false
  end

  def down
    remove_column :legacy_appeals, :burn_pit
    remove_column :legacy_appeals, :military_sexual_trauma
    remove_column :legacy_appeals, :blue_water
    remove_column :legacy_appeals, :us_court_of_appeals_for_veterans_claims
    remove_column :legacy_appeals, :no_special_issues
  end
end
