class CreateLegacyAppeals < ActiveRecord::Migration[5.1]
  def change
    create_table :legacy_appeals do |t|
      t.string    :vacols_id, null: false
      t.string    :vbms_id
      t.boolean   :rice_compliance, default: false
      t.boolean   :private_attorney_or_agent, default: false
      t.boolean   :waiver_of_overpayment, default: false
      t.boolean   :pension_united_states, default: false
      t.boolean   :vamc, default: false
      t.boolean   :incarcerated_veterans, default: false
      t.boolean   :dic_death_or_accrued_benefits_united_states, default: false
      t.boolean   :vocational_rehab, default: false
      t.boolean   :foreign_claim_compensation_claims_dual_claims_appeals, default: false
      t.boolean   :manlincon_compliance, default: false
      t.boolean   :hearing_including_travel_board_video_conference, default: false
      t.boolean   :home_loan_guarantee, default: false
      t.boolean   :insurance, default: false
      t.boolean   :national_cemetery_administration, default: false
      t.boolean   :spina_bifida, default: false
      t.boolean   :radiation, default: false
      t.boolean   :nonrating_issue, default: false
      t.boolean   :us_territory_claim_philippines, default: false
      t.boolean   :contaminated_water_at_camp_lejeune, default: false
      t.boolean   :mustard_gas, default: false
      t.boolean   :education_gi_bill_dependents_educational_assistance_scholars, default: false
      t.boolean   :foreign_pension_dic_all_other_foreign_countries, default: false
      t.boolean   :foreign_pension_dic_mexico_central_and_south_american_caribb, default: false
      t.boolean   :us_territory_claim_american_samoa_guam_northern_mariana_isla, default: false
      t.boolean   :us_territory_claim_puerto_rico_and_virgin_islands, default: false
      t.string    :dispatched_to_station
      t.boolean   :issues_pulled
    end
    add_index(:legacy_appeals, :vacols_id, unique: true)
  end
end
