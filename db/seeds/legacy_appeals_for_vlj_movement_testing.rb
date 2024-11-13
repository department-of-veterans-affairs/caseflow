# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_6_id_values
    end

    def seed!
      # place seed method calls here
      scenario_6_seeds
    end

    private

    # place seed methods below
    def initial_scenario_6_id_values
      @scenario_6_file_number ||= 700_000_000
      @scenario_6_participant_id ||= 530_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @scenario_6_file_number + 1))
        @scenario_6_file_number += 2000
        @scenario_6_participant_id += 2000
      end
    end

    def create_scenario_6_veteran(options = {})
      @scenario_6_file_number += 1
      @scenario_6_participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @scenario_6_file_number),
        participant_id: format("%<n>09d", n: @scenario_6_participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def scenario_6_seeds
      wqjudge_one = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "One")
      wqjudge_two = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "Two")
      wqjudge_three = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "Three")
      wqjudge_four = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "Four")
      wqjudge_five = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "Five")
      wqjudge_six = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "Six")
      wqjudge_control = create_scenario_6_veteran(first_name: "Wqjudge", last_name: "Control")

      # Case 1: Wqjudge One (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVALSHIELDS"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_one.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Case 2: Wqjudge Two (Nonpriority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 3: Wqjudge Three (Nonpriority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id(""),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)))

      # Case 4: Wqjudge Four (Priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAJWEHNER1"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 5: Wqjudge Five (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAOTRANTOW"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Case 6: Wqjudge Six (Nonpriority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 7: Wqjudge Control (priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :assigned,
        :aod,
        bfcorlid: "#{wqjudge_control.file_number}S",
        user: User.find_by_css_id("BVAOTRANTOW"),
        assigner: User.find_by_css_id("BVAGSPORER")
      ))
    end

  end
end
