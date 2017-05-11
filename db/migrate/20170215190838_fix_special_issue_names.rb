class FixSpecialIssueNames < ActiveRecord::Migration
  def change
    rename_column :appeals, :private_attorney, :private_attorney_or_agent
    rename_column :appeals, :pensions, :pension_united_states
    rename_column :appeals, :dic_death_or_accrued_benefits, :dic_death_or_accrued_benefits_united_states
    rename_column :appeals, :education_or_vocational_rehab, :vocational_rehab
    rename_column :appeals, :hearings_travel_board_video_conference, :hearing_including_travel_board_video_conference
    rename_column :appeals, :home_loan_guaranty, :home_loan_guarantee
    rename_column :appeals, :nonrating_issues, :nonrating_issue
    rename_column :appeals, :foreign_claims, :foreign_claim_compensation_claims_dual_claims_appeals
    rename_column :appeals, :manila_remand, :us_territory_claim_philippines
    rename_column :appeals, :dependencies, :education_gi_bill_dependents_educational_assistance_scholars
    
    add_column :appeals, :foreign_pension_dic_all_other_foreign_countries, :boolean, default: false
    add_column :appeals, :foreign_pension_dic_mexico_central_and_south_american_caribb, :boolean, default: false
    add_column :appeals, :us_territory_claim_american_samoa_guam_northern_mariana_isla, :boolean, default: false
    add_column :appeals, :us_territory_claim_puerto_rico_and_virgin_islands, :boolean, default: false

    remove_column :appeals, :proposed_incompetency
  end
end
