# frozen_string_literal: true

FactoryBot.define do
  # these get the highest existing value within the filter and uses that + 1 as the
  # initial value; filter values gives sufficient margin to allow seeds to be run hundreds
  # of times before a data collision occurs
  correspondent_key_initial_value =
    VACOLS::Correspondent.all.map(&:stafkey).map(&:to_i).filter { |key| key < 49_999 }.max.to_i + 1

  case_key_initial_value =
    VACOLS::Case.all.map(&:bfkey).map(&:to_i).filter { |key| key < 99_999 }.max.to_i + 1

  veteran_initial_value = Veteran.all.map(&:file_number).max.to_i + 1

  contention_reference_initial_value =
    RequestIssue.all.map(&:contention_reference_id).map(&:to_i).filter { |id| id < 100_000 }.max.to_i + 1

  # BRIEFF.BFCORLID in VACOLS, file_number/veteran_file_number in Caseflow
  sequence :veteran_file_number, veteran_initial_value do |n|
    format("%<n>09d", n: n)
  end

  # CORRES.STAFKEY, BRIEFF.BFCORKEY, FOLDER.TICKNUM
  sequence :vacols_correspondent_key, correspondent_key_initial_value

  # BRIEFF.BFKEY
  sequence :vacols_case_key, case_key_initial_value

  # used in decision_issues factory
  sequence :contention_reference_id, contention_reference_initial_value
end
