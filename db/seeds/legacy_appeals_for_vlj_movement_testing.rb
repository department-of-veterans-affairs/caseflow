# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_6_id_values
    end

    def seed!
      scenario_6_seeds
    end

    private

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

      def set_decass_atty(atty, sc)
        QueueRepository.send(:update_decass_record, VACOLS::Decass.find_by(defolder: sc.vacols_id), attorney_id: atty.vacols_attorney_id)
      end

      # Case 1: Wqjudge One (Priority, 2 issues)
      attorney = User.find_by_css_id("BVALSHIELDS")
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: attorney,
        bfcorlid: "#{wqjudge_one.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))
      set_decass_atty(attorney, scenario_case)


      # Case 2: Wqjudge Two (Nonpriority, 1 issue)
      attorney = User.find_by_css_id("BVACOTBJUDGE")
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: attorney,
        bfcorlid: "#{wqjudge_two.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
      set_decass_atty(attorney, scenario_case)

      # Case 3: Wqjudge Three (Nonpriority, 2 issues)
      attorney = User.find_by_css_id("BVALSHIELDS")
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVACOTBJUDGE"),
        assigner: attorney,
        bfcorlid: "#{wqjudge_three.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))
      set_decass_atty(attorney, scenario_case)

      # Case 4: Wqjudge Four (Priority, 1 issue)
      attorney = User.find_by_css_id("BVAJWEHNER1")
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case:
      create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: attorney,
        bfcorlid: "#{wqjudge_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
      set_decass_atty(attorney, scenario_case)

      # Case 5: Wqjudge Five (Priority, 2 issues)
      attorney = User.find_by_css_id("BVAOTRANTOW")
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case:
      create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :aod,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: attorney,
        bfcorlid: "#{wqjudge_five.file_number}S",
        case_issues: create_list(:case_issue, 2, :compensation)
      ))
      set_decass_atty(attorney, scenario_case)

      # Case 6: Wqjudge Six (Nonpriority, 1 issue)
      attorney = User.find_by_css_id("BVAGSPORER")
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        :assigned,
        user: User.find_by_css_id("BVAGSPORER"),
        assigner: attorney,
        bfcorlid: "#{wqjudge_six.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
      set_decass_atty(attorney, scenario_case)

      # Case 7: Wqjudge Control (priority, 1 issue)
      scenario_case = create(:legacy_appeal, :with_veteran, vacols_case: create(
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
