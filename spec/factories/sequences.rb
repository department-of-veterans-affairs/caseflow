# frozen_string_literal: true

FactoryBot.define do
  # get the highest existing value within the filter for each table and use that + 1 as the
  # initial value; filter values gives sufficient margin to allow seeds to be run hundreds
  # of times before a data collision occurs
  # if a table doesn't yet exist the rescued error will occur, in that case set the value to 1
  begin
    correspondent_key_initial_value =
      VACOLS::Correspondent.all.map(&:stafkey).map(&:to_i).filter { |key| key < 49_999 }.max.to_i + 1
  rescue ActiveRecord::StatementInvalid => error
    raise if !error.message.include?("PG::UndefinedTable")

    correspondent_key_initial_value = 1
  end

  begin
    case_key_initial_value =
      VACOLS::Case.all.map(&:bfkey).map(&:to_i).filter { |key| key < 99_999 }.max.to_i + 1
  rescue ActiveRecord::StatementInvalid => error
    raise if !error.message.include?("PG::UndefinedTable")

    case_key_initial_value = 1
  end

  begin
    contention_reference_initial_value =
      RequestIssue.all.map(&:contention_reference_id).map(&:to_i).filter { |id| id < 100_000 }.max.to_i + 1
  rescue ActiveRecord::StatementInvalid => error
    raise if !error.message.include?("PG::UndefinedTable")

    contention_reference_initial_value = 1
  end

  begin
    veteran_initial_value = Veteran.all.map(&:file_number).max.to_i + 1
  rescue ActiveRecord::StatementInvalid => error
    raise if !error.message.include?("PG::UndefinedTable")

    veteran_initial_value = 1
  end

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
