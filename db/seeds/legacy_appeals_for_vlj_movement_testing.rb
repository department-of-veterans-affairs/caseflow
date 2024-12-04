# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_3_id_values
    end

    def seed!
      scenario_3_seeds
    end

    private

    def initial_scenario_3_id_values
      @scenario_3_file_number ||= 800_000_000
      @scenario_3_participant_id ||= 900_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @scenario_3_file_number + 1))
        @scenario_3_file_number += 2000
        @scenario_3_participant_id += 2000
      end
    end

    def create_scenario_3_veteran(options = {})
      @scenario_3_file_number += 1
      @scenario_3_participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @scenario_3_file_number),
        participant_id: format("%<n>09d", n: @scenario_3_participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def scenario_3_seeds
      draft_one = create_scenario_3_veteran(first_name: "Aq'swap", last_name: "One")
      draft_two = create_scenario_3_veteran(first_name: "Aq'swap", last_name: "Two")
      draft_three = create_scenario_3_veteran(first_name: "Aq'swap", last_name: "Three")
      draft_four = create_scenario_3_veteran(first_name: "Aq'swap", last_name: "Four")
      draft_five = create_scenario_3_veteran(first_name: "Aq'swap", last_name: "Five")
      draft_six = create_scenario_3_veteran(first_name: "Aq'swap", last_name: "Six")
      not_draftable = create_scenario_3_veteran(first_name: "NotSwappable", last_name: "Control")

      # Scenario 1: Draft One (Primary, age-based, CAVC, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :aod,
        :assigned,
        :status_active,
        decass: false,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_one.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 2: Draft Two (Non-priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :assigned,
        :type_original,
        :status_active,
        decass: false,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 3: Draft Three (Non-priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :assigned,
        :type_original,
        :status_active,
        decass: false,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 4: Draft Four (Priority, manually added, CAVC, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :aod,
        :assigned,
        :status_active,
        decass: false,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 5: Draft Five (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :aod,
        :assigned,
        :type_original,
        :status_active,
        decass: false,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 6: Draft Six (Non-priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :assigned,
        :type_original,
        :status_active,
        decass: false,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 7: Not Draftable (Non-priority, 1 issue, not distributed yet)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :ready_for_distribution,
        :type_original,
        :status_active,
        bfcorlid: "#{not_draftable.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
    end
  end
end
