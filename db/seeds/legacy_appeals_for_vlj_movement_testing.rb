# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
    end

    def seed!
      # place seed method calls here
      scenario_4_seeds
    end

    private

    def create_scenario_4_veteran(options = {})
      create(:veteran, options)
    end

    # place seed methods below
    def scenario_4_seeds
      draft_one = create_scenario_4_veteran(first_name: "Attyswap", last_name: "One")
      draft_two = create_scenario_4_veteran(first_name: "Attyswap", last_name: "Two")
      draft_three = create_scenario_4_veteran(first_name: "Attyswap", last_name: "Three")
      draft_four = create_scenario_4_veteran(first_name: "Attyswap", last_name: "Four")
      draft_five = create_scenario_4_veteran(first_name: "Attyswap", last_name: "Five")
      draft_six = create_scenario_4_veteran(first_name: "Attyswap", last_name: "Six")
      not_swappable = create_scenario_4_veteran(first_name: "NotSwappable", last_name: "Control")

      # Scenario 1: Draft One (Primary, age-based, CAVC, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVALSHIELDS"),
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
        user: User.find_by_css_id("BVALSHIELDS"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 4: Draft Four (Priority, manually added, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAOTRANTOW"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 5: Draft Five (Priority, CAVC, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :type_cavc_remand,
        :assigned,
        user: User.find_by_css_id("BVAGBOTSFORD"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Scenario 6: Draft Six (Non-priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :assigned,
        user: User.find_by_css_id("BVAJWEHNER1"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: true,
        bfcorlid: "#{draft_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Scenario 7: Not Swappable (Non-priority, 1 issue, not distributed yet)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case,
        :ready_for_distribution,
        bfcorlid: "#{not_swappable.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
    end
  end
end
