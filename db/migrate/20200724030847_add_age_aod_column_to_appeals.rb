class AddAgeAodColumnToAppeals < ActiveRecord::Migration[5.2]
  def change
    add_column :appeals, :age_aod, :boolean, comment: "If true, appeal is advance-on-docket due to claimant's age."
  end
end
