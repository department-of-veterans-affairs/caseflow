class AddAgeAodColumnToAppeals < ActiveRecord::Migration[5.2]
  def change
    add_column :appeals, :aod_based_on_age, :boolean, comment: "If true, appeal is advance-on-docket due to claimant's age."
  end
end
