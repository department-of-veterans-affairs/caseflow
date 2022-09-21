# frozen_string_literal: true

FactoryBot.define do

  # begin
  #   # get the highest existing value within the filter for each table and use that + 1 as the
  #   # initial value; filter values gives sufficient margin to allow seeds to be run hundreds
  #   # of times before a data collision occurs
  #   # if a table doesn't yet exist the rescued error will occur, in that case set the value to 1
  #   begin
  #     correspondent_key_initial_value =
  #       VACOLS::Correspondent.all.map(&:stafkey).map(&:to_i).filter { |key| key < 49_999 }.max.to_i + 1
  #   rescue ActiveRecord::StatementInvalid => error
  #     raise if !error.message.include?("PG::UndefinedTable")
  #
  #     correspondent_key_initial_value = 1
  #   end
  #
  #   begin
  #     case_key_initial_value =
  #       VACOLS::Case.all.map(&:bfkey).map(&:to_i).filter { |key| key < 99_999 }.max.to_i + 1
  #   rescue ActiveRecord::StatementInvalid => error
  #     raise if !error.message.include?("PG::UndefinedTable")
  #
  #     case_key_initial_value = 1
  #   end
  #
  #   begin
  #     veteran_initial_value = Veteran.all.map(&:file_number).max.to_i + 1
  #   rescue ActiveRecord::StatementInvalid => error
  #     raise if !error.message.include?("PG::UndefinedTable")
  #
  #     veteran_initial_value = 1
  #   end
  #
  #   begin
  #     participant_id_initial_value =
  #       # < 1_000_000 avoids collisions with hard coded values for BGS fakes and sanitized JSON seeds
  #       Claimant.all.map(&:participant_id).map(&:to_i).filter { |id| id < 1_000_000 }.max
  #   rescue ActiveRecord::StatementInvalid => error
  #     raise if !error.message.include?("PG::UndefinedTable")
  #
  #     participant_id_initial_value = 1
  #   end
  # rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad => error
  #   raise if !error.message.include?('database "caseflow_certification_development" does not exist')
  #
  #   correspondent_key_initial_value = 1
  #   case_key_initial_value = 1
  #   veteran_initial_value = 1
  #   participant_id_initial_value = 1
  # end

  # BRIEFF.BFCORLID in VACOLS, file_number/veteran_file_number in Caseflow
  sequence :veteran_file_number, 1 do |n|
    format("%<n>09d", n: n)
  end

  # CORRES.STAFKEY, BRIEFF.BFCORKEY, FOLDER.TICKNUM
  sequence :vacols_correspondent_key, 1

  # BRIEFF.BFKEY
  sequence :vacols_case_key, 1

  # AMA factories: bgs_attorney, bgs_power_of_attorney, claimant, decision_issue, person, relationship, veteran
  sequence :participant_id, 1
end
