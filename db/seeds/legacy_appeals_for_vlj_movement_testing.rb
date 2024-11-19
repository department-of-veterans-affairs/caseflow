# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_7_id_values
    end

    def seed!
      scenario_7_seeds
    end

    private

    def initial_scenario_7_id_values
      @scenario_7_file_number ||= 790_000_000
      @scenario_7_participant_id ||= 590_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @scenario_7_file_number + 1))
        @scenario_7_file_number += 2000
        @scenario_7_participant_id += 2000
      end
    end

    def create_scenario_7_veteran(options = {})
      @scenario_7_file_number += 1
      @scenario_7_participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @scenario_7_file_number),
        participant_id: format("%<n>09d", n: @scenario_7_participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def scenario_7_seeds
      rewrite_one = create_scenario_7_veteran(first_name: "Rewrite", last_name: "One")
      rewrite_two = create_scenario_7_veteran(first_name: "Rewrite", last_name: "Two")
      rewrite_three = create_scenario_7_veteran(first_name: "Rewrite", last_name: "Three")
      rewrite_four = create_scenario_7_veteran(first_name: "Rewrite", last_name: "Four")
      rewrite_five = create_scenario_7_veteran(first_name: "Rewrite", last_name: "Five")
      rewrite_six = create_scenario_7_veteran(first_name: "Rewrite", last_name: "Six")
      no_rewrite_control = create_scenario_7_veteran(first_name: "NoRewrite ", last_name: "Control")

      # Case 1: Rewrite One (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVALSHIELDS"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewrite_one.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Case 2: Rewrite Two (Nonpriority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewrite_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 3: Rewrite Three (Nonpriority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVALSHIELDS"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewrite_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)))

      # Case 4: Rewrite Four (Priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAJWEHNER1"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewrite_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 5: Rewrite Five (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAOTRANTOW"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewrite_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Case 6: Rewrite Six (Nonpriority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewrite_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 7: NoRewrite Control (priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        :aod,
        assigner: User.find_by_css_id("BVAGSPORER"),
        bfcorlid: "#{no_rewrite_control.file_number}S",
        user: User.find_by_css_id("BVAOTRANTOW"),
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
    end
  end
end
