# frozen_string_literal: true

module Seeds
  class LegacyAppealsForVljMovementTesting < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_scenario_1_id_values
    end

    def seed!
      scenario_1_seeds
    end

    private

    def initial_scenario_1_id_values
      @scenario_1_file_number ||= 600_000_000
      @scenario_1_participant_id ||= 420_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @scenario_1_file_number + 1))
        @scenario_1_file_number += 2000
        @scenario_1_participant_id += 2000
      end
    end

    def create_scenario_1_veteran(options = {})
      @scenario_1_file_number += 1
      @scenario_1_participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @scenario_1_file_number),
        participant_id: format("%<n>09d", n: @scenario_1_participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def scenario_1_seeds
      hearblock_one = create_scenario_1_veteran(first_name: "HearBlock", last_name: "One")
      hearblock_two = create_scenario_1_veteran(first_name: "HearBlock", last_name: "Two")
      hearblock_three = create_scenario_1_veteran(first_name: "HearBlock", last_name: "Three")
      hearblock_cavc = create_scenario_1_veteran(first_name: "HearBlock", last_name: "CAVC")
      hearblock_four = create_scenario_1_veteran(first_name: "HearBlock", last_name: "Four")
      hearnon_block= create_scenario_1_veteran(first_name: "HearNon", last_name: "Block")
      doesnot_qualify = create_scenario_1_veteran(first_name: "DoesNot", last_name: "Qualify")

      2.times do
        # HearBlock One
        create(:legacy_appeal, :with_schedule_hearing_tasks, :with_veteran, vacols_case: create(
          :case_with_form_9,
          :aod,
          :type_original,
          :status_active,
          bfcorlid: "#{hearblock_one.file_number}S",
          case_issues: create_list(:case_issue, 1, :compensation)
          ))

        # HearBlock Two
        create(:legacy_appeal, :with_schedule_hearing_tasks, :with_veteran, vacols_case: create(
          :case_with_form_9,
          :type_original,
          :status_active,
          bfcorlid: "#{hearblock_two.file_number}S",
          case_issues: create_list(:case_issue, 2, :compensation)
          ))

        # HearBlock Three
        create(:legacy_appeal, :with_schedule_hearing_tasks, :with_veteran, vacols_case: create(
          :case_with_form_9,
          :aod,
          :type_original,
          :status_active,
          bfcorlid: "#{hearblock_three.file_number}S",
          case_issues: create_list(:case_issue, 2, :compensation)
        ))
      end

      # HearBlock CAVC
      create(:legacy_appeal, :with_schedule_hearing_tasks, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_cavc_remand,
        :status_active,
        bfcorlid: "#{hearblock_cavc.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # HearBlock Four
      create(:legacy_appeal, :with_schedule_hearing_tasks, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        bfcorlid: "#{hearblock_four.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # HearNon Block
      create(:legacy_appeal, :with_active_ihp_colocated_task, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :aod,
        :type_original,
        :status_active,
        bfcorlid: "#{hearnon_block.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))

      # DoesNot Qualify
      create(:legacy_appeal, :with_veteran, vacols_case: create(
        :case_with_form_9,
        :type_original,
        :status_active,
        bfcurloc: "83",
        bfcorlid: "#{doesnot_qualify.file_number}S",
        case_issues: create_list(:case_issue, 1, :compensation)
      ))
    end
  end
end
