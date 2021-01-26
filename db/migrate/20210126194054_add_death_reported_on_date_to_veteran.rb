class AddDeathReportedOnDateToVeteran < Caseflow::Migration
  def change
    add_column :veterans,
               :death_reported_on_date,
               :datetime,
               comment: "The datetime that date_of_death last changed for veteran."
  end
end
