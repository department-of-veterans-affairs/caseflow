class AddDateOfDeathReportedAtToVeteran < Caseflow::Migration
  def change
    add_column :veterans,
               :date_of_death_reported_at,
               :datetime,
               comment: "The datetime that date_of_death last changed for veteran."
  end
end
