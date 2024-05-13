# frozen_string_literal: true

module Seeds
  class CaseDistributionTestData < Base
    def initialize
      initialize_legacy_inactive_admin_judge_team_file_number_and_participant_id
      initialize_direct_review_file_number_and_participant_id
      initialize_ama_hearing_held_file_number_and_participant_id
      @current_attorney_index = 0
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_scenario_2_appeals
      create_scenario_3_appeals
      create_scenario_4_appeals
      create_scenario_5_appeals
      create_missing_tester_judges
    end

    private

    def create_scenario_2_appeals
      create_ama_hearing_held_aod_appeals(1, find_or_create_nontester_judge("BVAABSHIRE", "BVA Judge Abshire"), (20.years + 3.days).ago, 370.days.ago)
      create_ama_hearing_held_aod_appeals(4, find_or_create_tester_judge_team("BVAREDMAN", "BVA Judge Redman", 2), (20.years + 2.days).ago, 200.days.ago)
      create_create_legacy_appeals(6, (20.years + 1.day).ago, 390.days.ago)
      create_direct_review_appeals(7, (20.years + 1.day).ago, 390.days.ago)
    end

    def create_scenario_3_appeals
      create_ama_hearing_held_aod_appeals(4, find_or_create_nontester_judge("BVAABSHIRE", "BVA Judge Abshire"), (15.years + 3.days).ago, 20.days.ago)
      create_ama_hearing_held_aod_appeals(9, find_or_create_tester_judge_team("BVABECKER", "BVA Judge Becker", 3), (15.years + 2.days).ago, 8.days.ago)
      create_create_legacy_appeals(20, (15.years + 1.day).ago, 340.days.ago)
      create_direct_review_appeals(21, (15.years + 1.day).ago, 340.days.ago)
    end

    def create_scenario_4_appeals
      create_ama_hearing_held_aod_appeals(2, find_or_create_tester_judge_team("BVABECKER", "BVA Judge Becker", 3), (10.years + 2.days).ago, 7.days.ago)
      create_create_legacy_appeals(8, (10.years + 1.days).ago, 310.days.ago)
      create_direct_review_appeals(8, (10.years + 1.days).ago, 310.days.ago)
    end

    def create_scenario_5_appeals
      create_ama_hearing_held_aod_appeals(5, find_or_create_nontester_judge("BVAABSHIRE", "BVA Judge Abshire"), (5.years + 3.days).ago, 40.days.ago)
      create_ama_hearing_held_aod_appeals(10, find_or_create_tester_judge_team("BVABECKER", "BVA Judge Becker", 3), (5.years + 2.days).ago, 6.days.ago)
      create_create_legacy_appeals(1, (5.years + 1.day).ago, 290.days.ago)
      create_direct_review_appeals(2, (5.years + 1.day).ago, 290.days.ago)
    end

    # functions for initialization
    def initialize_legacy_inactive_admin_judge_team_file_number_and_participant_id
      @legacy_inactive_admin_judge_team_file_number ||= 703_000_200
      @legacy_inactive_admin_judge_team_participant_id ||= 713_000_000

      while find_veteran(@legacy_inactive_admin_judge_team_file_number)
        @legacy_inactive_admin_judge_team_file_number += 2000
        @legacy_inactive_admin_judge_team_participant_id += 2000
      end
    end

    def initialize_direct_review_file_number_and_participant_id
      @direct_review_file_number ||= 706_000_200
      @direct_review_participant_id ||= 716_000_000

      while find_veteran(@direct_review_file_number)
        @direct_review_file_number += 2000
        @direct_review_participant_id += 2000
      end
    end

    def initialize_ama_hearing_held_file_number_and_participant_id
      @ama_hearing_held_file_number ||= 709_000_200
      @ama_hearing_held_participant_id ||= 719_000_000

      while find_veteran(@ama_hearing_held_file_number)
        @ama_hearing_held_file_number += 2000
        @ama_hearing_held_participant_id += 2000
      end
    end

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    # functions for finding/creating data for appeals
    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }
      create(:veteran, params.merge(options))
    end

    def find_or_create_tester_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_nontester_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_inactive_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_inactive_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_tester_judge_team(css_id, full_name, number_of_attorneys)
      judge = find_or_create_tester_judge(css_id, full_name)
      judge_team = JudgeTeam.for_judge(judge)

      if judge_team.attorneys.count < number_of_attorneys
        (number_of_attorneys - judge_team.attorneys.count).times.each do |num|
          attorney = next_attorney
          add_attorney_to_judge_team(judge_team, attorney[:css_id], attorney[:full_name])
        end
      end

      judge
    end

    def add_attorney_to_judge_team(judge_team, css_id, full_name)
      user = User.find_by_css_id(css_id) ||
              create(:user, :with_vacols_attorney_record,
                    css_id: css_id, full_name: full_name)

      judge_team.add_user(user)
    end

    def attorney_names_and_css_ids
      [
        {full_name: "Attorney OnJudgeTeam Active1", css_id: "ACTIVEATYA"},
        {full_name: "Attorney OnJudgeTeam Active2", css_id: "ACTIVEATYB"},
        {full_name: "Attorney OnJudgeTeam Active3", css_id: "ACTIVEATYC"},
        {full_name: "Attorney OnJudgeTeam Active4", css_id: "ACTIVEATYD"},
        {full_name: "Attorney OnJudgeTeam Active5", css_id: "ACTIVEATYE"},
        {full_name: "Attorney OnJudgeTeam Active6", css_id: "ACTIVEATYF"},
        {full_name: "Attorney OnJudgeTeam Active7", css_id: "ACTIVEATYG"},
        {full_name: "Attorney OnJudgeTeam Active8", css_id: "ACTIVEATYH"},
        {full_name: "Attorney OnJudgeTeam Active9", css_id: "ACTIVEATYI"},
        {full_name: "Attorney OnJudgeTeam Active10", css_id: "ACTIVEATYJ"}
      ]
    end

    def next_attorney
      attorney = attorney_names_and_css_ids[@current_attorney_index]
      @current_attorney_index += 1

      attorney
    end

    def create_missing_tester_judges
      find_or_create_tester_judge("BVAKEELING", "BVA Judge Keeling")
      find_or_create_tester_judge("BVACOTBJ", "BVA ChairOfThe BoardJudge")
    end

    def regional_office
      'RO17'
    end

    # functions for creating appeals in batches
    def create_ama_hearing_held_aod_appeals(number_of_appeals_to_create, hearing_judge, receipt_date, appeal_affinity_start_date)
      number_of_appeals_to_create.times.each do
        create_ama_hearing_held_aod_appeal(hearing_judge, receipt_date, appeal_affinity_start_date)
      end
    end

    def create_create_legacy_appeals(number_of_appeals_to_create, receipt_date, appeal_affinity_start_date)
      number_of_appeals_to_create.times.each do
        create_legacy_appeal(receipt_date, appeal_affinity_start_date)
      end
    end

    def create_direct_review_appeals(number_of_appeals_to_create, receipt_date, assigned_at_date)
      number_of_appeals_to_create.times.each do
        create_direct_review_appeal(receipt_date, assigned_at_date)
      end
    end

    # AMA HH AOD appeal creation functions
    def create_ama_hearing_held_aod_appeal(hearing_judge, receipt_date, appeal_affinity_start_date)
      Timecop.travel(appeal_affinity_start_date)
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing_and_ready_to_distribute,
          :tied_to_judge,
          :with_appeal_affinity,
          veteran: create_veteran_for_ama_hearing_held_judge,
          receipt_date: receipt_date,
          tied_judge: hearing_judge,
          adding_user: User.first
        )
      Timecop.return
    end

    def create_veteran_for_ama_hearing_held_judge
      @ama_hearing_held_file_number += 1
      @ama_hearing_held_participant_id += 1
      create_veteran(
        file_number: @ama_hearing_held_file_number,
        participant_id: @ama_hearing_held_participant_id
      )
    end

    # Legacy appeal creation functions
    def create_legacy_appeal(receipt_date, appeal_affinity_start_date)
      Timecop.travel(appeal_affinity_start_date)
      veteran = create_veteran_for_legacy_inactive_admin_judge_team

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_video_vacols_case(veteran,
                                            correspondent,
                                            legacy_inactive_admin_judge_team,
                                            receipt_date)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)
      Timecop.return
    end

    def create_veteran_for_legacy_inactive_admin_judge_team
      @legacy_inactive_admin_judge_team_file_number += 1
      @legacy_inactive_admin_judge_team_participant_id += 1
      create_veteran(
        file_number: @legacy_inactive_admin_judge_team_file_number,
        participant_id: @legacy_inactive_admin_judge_team_participant_id
      )
    end

    def legacy_inactive_admin_judge_team
      @legacy_inactive_admin_judge_team ||= begin
        judge = find_or_create_inactive_judge("INACTIVECFJUDGE", "Judge InactiveInCF_AVLJ User")
        judge.update_status!("inactive") if judge.active?
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge
      end
    end

    def create_video_vacols_case(veteran, correspondent, judge, receipt_date)
      create(
        :case,
        :aod,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: judge,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: receipt_date
      )
    end

    # Direct review appeal creation functions
    def create_direct_review_appeal(receipt_date, assigned_at_date)
      Timecop.travel(assigned_at_date)
      create(
        :appeal,
        :direct_review_docket,
        :ready_for_distribution,
        :advanced_on_docket_due_to_age,
        associated_judge: inactive_hearing_direct_review_judge,
        veteran: create_veteran_for_direct_review,
        receipt_date: receipt_date
      )
      Timecop.return
    end

    def inactive_hearing_direct_review_judge
      @inactive_hearing_direct_review_judge ||=
        find_or_create_inactive_judge("JUDGEHEARING1", "Judge Hearings DirectReview")
    end

    def create_veteran_for_direct_review
      @direct_review_file_number += 1
      @direct_review_participant_id += 1
      create_veteran(file_number: @direct_review_file_number, participant_id: @direct_review_participant_id)
    end

  end
end
