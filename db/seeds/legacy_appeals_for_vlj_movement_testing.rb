# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_2_id_values
      initial_scenario_6_id_values
    end

    def seed!
      scenario_2_seeds
      scenario_6_seeds
    end

    private

    def initial_scenario_2_id_values
      @scenario_2_file_number ||= 123_000_000
      @scenario_2_participant_id ||= 123_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @scenario_2_file_number + 1))
        @scenario_2_file_number += 2000
        @scenario_2_participant_id += 2000
      end
    end

    def create_scenario_2_veteran(options = {})
      @scenario_2_file_number += 1
      @scenario_2_participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @scenario_2_file_number),
        participant_id: format("%<n>09d", n: @scenario_2_participant_id)
      }
      create(:veteran, params.merge(options))
    end

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

    def scenario_2_seeds
      s2_vet_1 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "One")
      s2_vet_2 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "Two")
      s2_vet_3 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "Three")
      s2_vet_4 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "Four")
      s2_vet_5 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "Five")
      s2_vet_6 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "Six")
      s2_vet_7 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "CAVC")
      s2_vet_8 = create_scenario_2_veteran(first_name: "HearNoBlock", last_name: "Eight")
      s2_vet_9 = create_scenario_2_veteran(first_name: "HearBlock", last_name: "Nine")
      s2_vet_10 = create_scenario_2_veteran(first_name: "DoesNot", last_name: "Qualify")

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_1.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_2.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_3.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_4.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_5.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_6.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_7.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :ready_for_distribution,
        bfcorlid: "#{s2_vet_8.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      create(:legacy_appeal, :with_schedule_hearing_tasks, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        bfcorlid: "#{s2_vet_9.file_number}S",
        bfcurloc: "CASEFLOW",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        bfcorlid: "#{s2_vet_10.file_number}S",
        bfcurloc: "33",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
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
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
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
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 3: Wqjudge Three (Nonpriority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVALSHIELDS"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)))

      # Case 4: Wqjudge Four (Priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
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
        :case_with_form_9,
        :type_original,
        :status_active,
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
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: false,
        bfcorlid: "#{wqjudge_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 7: Wqjudge Control (priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        :aod,
        bfcorlid: "#{wqjudge_control.file_number}S",
        user: User.find_by_css_id("BVAOTRANTOW"),
        assigner: User.find_by_css_id("BVAGSPORER")
      ))
    end

  end
end
