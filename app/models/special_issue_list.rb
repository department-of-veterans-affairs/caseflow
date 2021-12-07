# frozen_string_literal: true

class SpecialIssueList < CaseflowRecord
  include HasAppealUpdatedSince

  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: special_issue_lists
#
#  id                                                           :bigint           not null, primary key
#  appeal_type                                                  :string           indexed => [appeal_id]
#  blue_water                                                   :boolean          default(FALSE)
#  burn_pit                                                     :boolean          default(FALSE)
#  contaminated_water_at_camp_lejeune                           :boolean          default(FALSE)
#  dic_death_or_accrued_benefits_united_states                  :boolean          default(FALSE)
#  education_gi_bill_dependents_educational_assistance_scholars :boolean          default(FALSE)
#  foreign_claim_compensation_claims_dual_claims_appeals        :boolean          default(FALSE)
#  foreign_pension_dic_all_other_foreign_countries              :boolean          default(FALSE)
#  foreign_pension_dic_mexico_central_and_south_america_caribb  :boolean          default(FALSE)
#  hearing_including_travel_board_video_conference              :boolean          default(FALSE)
#  home_loan_guaranty                                           :boolean          default(FALSE)
#  incarcerated_veterans                                        :boolean          default(FALSE)
#  insurance                                                    :boolean          default(FALSE)
#  manlincon_compliance                                         :boolean          default(FALSE)
#  military_sexual_trauma                                       :boolean          default(FALSE)
#  mustard_gas                                                  :boolean          default(FALSE)
#  national_cemetery_administration                             :boolean          default(FALSE)
#  no_special_issues                                            :boolean          default(FALSE)
#  nonrating_issue                                              :boolean          default(FALSE)
#  pension_united_states                                        :boolean          default(FALSE)
#  private_attorney_or_agent                                    :boolean          default(FALSE)
#  radiation                                                    :boolean          default(FALSE)
#  rice_compliance                                              :boolean          default(FALSE)
#  spina_bifida                                                 :boolean          default(FALSE)
#  us_court_of_appeals_for_veterans_claims                      :boolean          default(FALSE)
#  us_territory_claim_american_samoa_guam_northern_mariana_isla :boolean          default(FALSE)
#  us_territory_claim_philippines                               :boolean          default(FALSE)
#  us_territory_claim_puerto_rico_and_virgin_islands            :boolean          default(FALSE)
#  vamc                                                         :boolean          default(FALSE)
#  vocational_rehab                                             :boolean          default(FALSE)
#  waiver_of_overpayment                                        :boolean          default(FALSE)
#  created_at                                                   :datetime
#  updated_at                                                   :datetime         indexed
#  appeal_id                                                    :bigint           indexed => [appeal_type]
#
