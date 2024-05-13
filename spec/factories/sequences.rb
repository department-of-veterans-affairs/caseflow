# frozen_string_literal: true

FactoryBot.define do
  # returns digits 4-8 of epoch time to be used for unique id sequencing
  def time
    Time.now.to_i.to_s.split("")[3..7].join
  end

  # returns digits 7-10 of epoch time for use in CSS_ID sequencing
  def shortened_time
    Time.now.to_i.to_s.split("")[6..9].join
  end

  # BRIEFF.BFCORLID in VACOLS, file_number/veteran_file_number in Caseflow
  sequence :veteran_file_number do |n|
    FactoryBot.sequence_by_name(:veteran_file_number).rewind if n == 9999
    time.concat(format("%<n>04d", n: n))
  end

  # CORRES.STAFKEY, BRIEFF.BFCORKEY, FOLDER.TICKNUM
  sequence :vacols_correspondent_key do |n|
    FactoryBot.sequence_by_name(:vacols_correspondent_key).rewind if n == 9999
    time.concat(format("%<n>04d", n: n))
  end

  # BRIEFF.BFKEY
  sequence :vacols_case_key do |n|
    FactoryBot.sequence_by_name(:vacols_case_key).rewind if n == 9999
    time.concat(format("%<n>04d", n: n))
  end

  # AMA factories: bgs_attorney, bgs_power_of_attorney, claimant, decision_issue, person, relationship, veteran
  sequence :participant_id do |n|
    FactoryBot.sequence_by_name(:participant_id).rewind if n == 9999
    time.concat(format("%<n>04d", n: n))
  end

  # User factory
  # sequence :css_id do |n|
  #   FactoryBot.sequence_by_name(:css_id).rewind if n == 999
  #   shortened_time.concat(format("%<n>03d", n: n))
  # end
  sequence :css_id

  sequence :sattyid
end
