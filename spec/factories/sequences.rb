# frozen_string_literal: true

FactoryBot.define do
  # returns digits 4-8 of epoch time to be used for unique id sequencing
  def time
    Time.now.to_i.to_s.split("")[3..7].join
  end

  # BRIEFF.BFCORLID in VACOLS, file_number/veteran_file_number in Caseflow
  sequence :veteran_file_number do |n|
    FactoryBot.rewind_sequences if n == 9999
    time.concat(format("%<n>05d", n: n))
  end

  # CORRES.STAFKEY, BRIEFF.BFCORKEY, FOLDER.TICKNUM
  sequence :vacols_correspondent_key do |n|
    FactoryBot.rewind_sequences if n == 9999
    time.concat(format("%<n>05d", n: n))
  end

  # BRIEFF.BFKEY
  sequence :vacols_case_key do |n|
    FactoryBot.rewind_sequences if n == 9999
    time.concat(format("%<n>05d", n: n))
  end

  # AMA factories: bgs_attorney, bgs_power_of_attorney, claimant, decision_issue, person, relationship, veteran
  sequence :participant_id do |n|
    FactoryBot.rewind_sequences if n == 9999
    time.concat(format("%<n>05d", n: n))
  end
end
