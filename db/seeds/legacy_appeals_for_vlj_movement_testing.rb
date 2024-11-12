# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_5_id_values
    end

    def seed!
      scenario_5_seeds
    end

    private

    def initial_scenario_5_id_values
      @scenario_5_file_number ||= 800_000_000
      @scenario_5_participant_id ||= 900_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @scenario_5_file_number + 1))
        @scenario_5_file_number += 2000
        @scenario_5_participant_id += 2000
      end
    end

    def create_scenario_5_veteran(options = {})
      @scenario_5_file_number += 1
      @scenario_5_participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @scenario_5_file_number),
        participant_id: format("%<n>09d", n: @scenario_5_participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def scenario_5_seeds
      draft_one = create_scenario_5_veteran(first_name: "Draft", last_name: "One")
      draft_two = create_scenario_5_veteran(first_name: "Draft", last_name: "Two")
      draft_three = create_scenario_5_veteran(first_name: "Draft", last_name: "Three")
      draft_four = create_scenario_5_veteran(first_name: "Draft", last_name: "Four")
      draft_five = create_scenario_5_veteran(first_name: "Draft", last_name: "Five")
      draft_six = create_scenario_5_veteran(first_name: "Draft", last_name: "Six")
      not_draftable = create_scenario_5_veteran(first_name: "Control", last_name: "NotDraftable")

      # Scenario 1: Draft One (Primary, age-based, CAVC, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_one.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 2: Draft Two (Non-priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 3: Draft Three (Non-priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 4: Draft Four (Priority, manually added, CAVC, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 5: Draft Five (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 6: Draft Six (Non-priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 7: Not Draftable (Non-priority, 1 issue, not distributed yet)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :ready_for_distribution,
        bfcorlid: "#{not_draftable.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
    end
  end
end
