class AddSpecialIssuesToAppeals < ActiveRecord::Migration
  def change
    add_column :appeals, :rice_compliance, :boolean, default: false
    add_column :appeals, :private_attorney, :boolean, default: false
    add_column :appeals, :waiver_of_overpayment, :boolean, default: false
    add_column :appeals, :pensions, :boolean, default: false
    add_column :appeals, :vamc, :boolean, default: false
    add_column :appeals, :incarcerated_veterans, :boolean, default: false
    add_column :appeals, :dic_death_or_accrued_benefits, :boolean, default: false
    add_column :appeals, :education_or_vocational_rehab, :boolean, default: false
    add_column :appeals, :foreign_claims, :boolean, default: false
    add_column :appeals, :manlincon_compliance, :boolean, default: false
    add_column :appeals, :hearings_travel_board_video_conference, :boolean, default: false
    add_column :appeals, :home_loan_guaranty, :boolean, default: false
    add_column :appeals, :insurance, :boolean, default: false
    add_column :appeals, :national_cemetery_administration, :boolean, default: false
    add_column :appeals, :spina_bifida, :boolean, default: false
    add_column :appeals, :radiation, :boolean, default: false
    add_column :appeals, :nonrating_issues, :boolean, default: false
    add_column :appeals, :proposed_incompetency, :boolean, default: false
    add_column :appeals, :manila_remand, :boolean, default: false
    add_column :appeals, :contaminated_water_at_camp_lejeune, :boolean, default: false
    add_column :appeals, :mustard_gas, :boolean, default: false
    add_column :appeals, :dependencies, :boolean, default: false
  end
end
