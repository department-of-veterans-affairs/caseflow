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
      rewite_one = create_scenario_7_veteran(first_name: "Rewite", last_name: "One")
      rewite_two = create_scenario_7_veteran(first_name: "Rewite", last_name: "Two")
      rewite_three = create_scenario_7_veteran(first_name: "Rewite", last_name: "Three")
      rewite_four = create_scenario_7_veteran(first_name: "Rewite", last_name: "Four")
      rewite_five = create_scenario_7_veteran(first_name: "Rewite", last_name: "Five")
      rewite_six = create_scenario_7_veteran(first_name: "Rewite", last_name: "Six")
      no_rewite_control = create_scenario_7_veteran(first_name: "NoRewite ", last_name: "Control")

      # Case 1: Rewite One (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVALSHIELDS"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewite_one.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Case 2: Rewite Two (Nonpriority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVACOTBJUDGE"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewite_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 3: Rewite Three (Nonpriority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: User.find_by_css_id("BVALSHIELDS"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewite_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)))

      # Case 4: Rewite Four (Priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAJWEHNER1"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewite_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 5: Rewite Five (Priority, 2 issues)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAOTRANTOW"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewite_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))

      # Case 6: Rewite Six (Nonpriority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: User.find_by_css_id("BVAGSPORER"),
        as_judge_assign_task: false,
        bfcorlid: "#{rewite_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # Case 7: NoRewite Control (priority, 1 issue)
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        :aod,
        bfcorlid: "#{no_rewite_control.file_number}S",
        user: User.find_by_css_id("BVAOTRANTOW"),
        assigner: User.find_by_css_id("BVAGSPORER")
      ))
    end
  end
end
