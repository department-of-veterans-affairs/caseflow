# frozen_string_literal: true

FactoryBot.define do
  # these get the highest existing value within the filter and uses that + 1 as the
  # initial value; filter values gives sufficient margin to allow seeds to be run hundreds
  # of times before a data collision occurs
  correspondend_key_initial_value = 
    VACOLS::Correspondent.all.map(&:stafkey).map(&:to_i).filter { |key| key < 49_999 }.max + 1
  case_key_initial_value =
    VACOLS::Case.all.map(&:bfkey).map(&:to_i).filter { |key| key < 99_999 }.max + 1
  veteran_initial_value = Veteran.all.map(&:file_number).max.to_i + 1

  # BRIEFF.BFCORLID in VACOLS, file_number/veteran_file_number in Caseflow
  sequence :veteran_file_number, veteran_initial_value do |n|
    format("%<n>09d", n: n)
  end

  # CORRES.STAFKEY, BRIEFF.BFCORKEY, FOLDER.TICKNUM
  sequence :vacols_correspondent_key, correspondend_key_initial_value

  # BRIEFF.BFKEY
  sequence :vacols_case_key, case_key_initial_value
end
