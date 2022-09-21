# frozen_string_literal: true

FactoryBot.define do
  # BRIEFF.BFCORLID in VACOLS, file_number/veteran_file_number in Caseflow
  sequence :veteran_file_number, veteran_initial_value do |n|
    format("%<n>09d", n: n)
  end

  # CORRES.STAFKEY, BRIEFF.BFCORKEY, FOLDER.TICKNUM
  sequence :vacols_correspondent_key, correspondent_key_initial_value

  # BRIEFF.BFKEY
  sequence :vacols_case_key, case_key_initial_value

  # AMA factories: bgs_attorney, bgs_power_of_attorney, claimant, decision_issue, person, relationship, veteran
  sequence :participant_id, participant_id_initial_value
end
