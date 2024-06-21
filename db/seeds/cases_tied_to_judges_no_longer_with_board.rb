# frozen_string_literal: true

module Seeds
  class CasesTiedToJudgesNoLongerWithBoard < Base
    APPEALS_LIMIT = 10

    def initialize
      initialize_inactive_cf_user_and_inactive_admin_judge_team_file_number_and_participant_id
      initialize_active_cf_user_and_non_admin_judge_team_file_number_and_participant_id
      initialize_active_cf_user_and_inactive_judge_team_file_number_and_participant_id
      initialize_active_judge_file_number_and_participant_id
      initialize_active_vacols_user_with_only_sattyid_file_number_and_participant_id
      initialize_inactive_judge_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_legacy_appeals
      create_ama_appeals
    end

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def initialize_inactive_cf_user_and_inactive_admin_judge_team_file_number_and_participant_id
      @inactive_cf_user_and_inactive_admin_judge_team_file_number ||= 700_000_000
      @inactive_cf_user_and_inactive_admin_judge_team_participant_id ||= 710_000_000

      while find_veteran(@inactive_cf_user_and_inactive_admin_judge_team_file_number)
        @inactive_cf_user_and_inactive_admin_judge_team_file_number += 2000
        @inactive_cf_user_and_inactive_admin_judge_team_participant_id += 2000
      end
    end

    def initialize_active_cf_user_and_non_admin_judge_team_file_number_and_participant_id
      @active_cf_user_and_non_admin_judge_team_file_number ||= 701_000_000
      @active_cf_user_and_non_admin_judge_team_participant_id ||= 711_000_000

      while find_veteran(@active_cf_user_and_non_admin_judge_team_file_number)
        @active_cf_user_and_non_admin_judge_team_file_number += 2000
        @active_cf_user_and_non_admin_judge_team_participant_id += 2000
      end
    end

    def initialize_active_cf_user_and_inactive_judge_team_file_number_and_participant_id
      @active_cf_user_and_inactive_judge_team_file_number ||= 702_000_000
      @active_cf_user_and_inactive_judge_team_participant_id ||= 712_000_000

      while find_veteran(@active_cf_user_and_inactive_judge_team_file_number)
        @active_cf_user_and_inactive_judge_team_file_number += 2000
        @active_cf_user_and_inactive_judge_team_participant_id += 2000
      end
    end

    def initialize_active_judge_file_number_and_participant_id
      @file_number ||= 703_000_200
      @participant_id ||= 713_000_000

      while find_veteran(@file_number)
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def initialize_active_vacols_user_with_only_sattyid_file_number_and_participant_id
      @active_vacols_user_with_only_sattyid_file_number ||= 704_000_000
      @active_vacols_user_with_only_sattyid_participant_id ||= 714_000_000
      while find_veteran(@active_vacols_user_with_only_sattyid_file_number)
        @active_vacols_user_with_only_sattyid_file_number += 2000
        @active_vacols_user_with_only_sattyid_participant_id += 2000
      end
    end

    def initialize_inactive_judge_file_number_and_participant_id
      @inactive_judge_file_number ||= 705_000_000
      @inactive_judge_participant_id ||= 715_000_000

      while find_veteran(@inactive_judge_file_number)
        @inactive_judge_file_number += 2000
        @inactive_judge_participant_id += 2000
      end
    end

    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }
      create(:veteran, params.merge(options))
    end

    def find_or_create_active_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_inactive_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_inactive_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_active_judge_with_only_sattyid(css_id, full_name)
      User.find_by_css_id(css_id) || create(:user, :with_vacols_record_satty_id, css_id: css_id, full_name: full_name)
    end

    def inactive_cf_user_and_inactive_admin_judge_team
      @inactive_cf_user_and_inactive_admin_judge_team ||= begin
        judge = find_or_create_active_judge("INACTIVECFJUDGE", "Judge InactiveInCF User")
        judge.update_status!("inactive") if judge.active?
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge
      end
    end

    # Active Caseflow User who is not the admin of any JudgeTeam.
    def active_cf_user_and_non_admin_judge_team
      @active_cf_user_and_non_admin_judge_team ||= begin
        judge = find_or_create_active_judge("ACTIVEJUDGETEAM", "Judge WithJudgeTeam Active")
        judge_team = JudgeTeam.for_judge(judge)

        user = User.find_by_css_id("ACTIVEATTY") ||
               create(:user, :with_vacols_attorney_record,
                      css_id: "ACTIVEATTY", full_name: "Attorney OnJudgeTeam Active")
        judge_team.add_user(user)

        user
      end
    end

    # Active Caseflow User who is the admin of an Inactive JudgeTeam and a non-admin of another JudgeTeam
    def active_cf_user_and_inactive_judge_team
      @active_cf_user_and_inactive_judge_team ||= begin
        user = User.find_by_css_id("ATTYWITHTEAM") ||
               create(:user,
                      :judge,
                      :with_vacols_acting_judge_record,
                      css_id: "ATTYWITHTEAM",
                      full_name: "Attorney WithInactiveJudgeTeam Affinity")

        JudgeTeam.for_judge(user)&.inactive!
        another_judge = find_or_create_active_judge("ACTIVEJUDGETEAM", "Judge WithJudgeTeam Active")
        another_judge_team = JudgeTeam.for_judge(another_judge)
        another_judge_team.add_user(user)

        user
      end
    end

    def active_judge_hearing_affinity_45_days
      @active_judge_hearing_affinity_45_days ||=
        find_or_create_active_judge("JUDGEHEARING1", "Judge Hearings45Days Affinity")
    end

    def active_judge_hearing_affinity_65_days
      @active_judge_hearing_affinity_65_days ||=
        find_or_create_active_judge("JUDGEHEARING2", "Judge Hearings65Days Affinity")
    end

    def inactive_vacols_judge
      @inactive_vacols_judge ||= find_or_create_inactive_judge("INACTIVEJUDGE", "Judge InactiveInVacols User")
    end

    def active_vacols_user_with_only_sattyid
      @active_vacols_user_with_only_sattyid ||=
        find_or_create_active_judge_with_only_sattyid("SATTYIDUSER", "User WithOnly Sattyid")
    end

    def create_legacy_appeals
      Timecop.travel(65.days.ago)
      APPEALS_LIMIT.times.each do
        create_vacols_case_tied_to_inactive_judge
        create_vacols_case_tied_to_active_vacols_user_with_only_sattyid
        create_vacols_case_for_active_judge
        create_vacols_case_for_inactive_judge
      end
      Timecop.return
    end

    def create_vacols_case_tied_to_inactive_judge
      # Create the veteran for this legacy appeal
      veteran = create_veteran_for_inactive_cf_user_and_inactive_admin_judge_team

      regional_office = "RO17"

      # AC1: create legacy appeals ready to be distributed that have a hearing held by an inactive judge
      correspondent = create(:correspondent,
                             snamef: veteran.first_name, snamel: veteran.last_name,
                             ssalut: "", ssn: veteran.file_number)

      vacols_case = create_video_vacols_case(veteran,
                                             correspondent,
                                             inactive_cf_user_and_inactive_admin_judge_team)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      vacols_case
    end

    def create_vacols_case_tied_to_active_vacols_user_with_only_sattyid
      # Create the veteran for this legacy appeal
      veteran = create_veteran_for_active_vacols_user_with_only_sattyid

      regional_office = "RO17"
      # create legacy appeals ready to be distributed that have a hearing held by an active user with only sattyid
      correspondent = create(:correspondent,
                             snamef: veteran.first_name, snamel: veteran.last_name,
                             ssalut: "", ssn: veteran.file_number)

      vacols_case = create_video_vacols_case(veteran,
                                             correspondent,
                                             active_vacols_user_with_only_sattyid)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      vacols_case
    end

    def create_vacols_case_for_active_judge
      # Create the veteran for this legacy appeal
      veteran = create_veteran_for_active_judge

      regional_office = "RO17"

      correspondent = create(:correspondent,
                             snamef: veteran.first_name, snamel: veteran.last_name,
                             ssalut: "", ssn: veteran.file_number)

      vacols_case = create_video_vacols_case(veteran,
                                             correspondent,
                                             active_judge_hearing_affinity_45_days)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      vacols_case
    end

    def create_vacols_case_for_inactive_judge
      # Create the veteran for this legacy appeal
      veteran = create_veteran_for_inactive_judge

      regional_office = "RO17"
      # AC1: create legacy appeals ready to be distributed that have a hearing held by an inactive judge
      correspondent = create(:correspondent,
                             snamef: veteran.first_name, snamel: veteran.last_name,
                             ssalut: "", ssn: veteran.file_number)

      vacols_case = create_video_vacols_case(veteran,
                                             correspondent,
                                             inactive_vacols_judge)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      vacols_case
    end

    def create_veteran_for_inactive_cf_user_and_inactive_admin_judge_team
      @inactive_cf_user_and_inactive_admin_judge_team_file_number += 1
      @inactive_cf_user_and_inactive_admin_judge_team_participant_id += 1
      create_veteran(
        file_number: @inactive_cf_user_and_inactive_admin_judge_team_file_number,
        participant_id: @inactive_cf_user_and_inactive_admin_judge_team_participant_id
      )
    end

    def create_veteran_for_active_vacols_user_with_only_sattyid
      @active_vacols_user_with_only_sattyid_file_number += 1
      @active_vacols_user_with_only_sattyid_participant_id += 1
      create_veteran(
        file_number: @active_vacols_user_with_only_sattyid_file_number,
        participant_id: @active_vacols_user_with_only_sattyid_participant_id
      )
    end

    def create_veteran_for_inactive_judge
      @inactive_judge_file_number += 1
      @inactive_judge_participant_id += 1
      create_veteran(
        file_number: @inactive_judge_file_number,
        participant_id: @inactive_judge_participant_id
      )
    end

    def create_veteran_for_active_judge
      @file_number += 1
      @participant_id += 1
      create_veteran(file_number: @file_number, participant_id: @participant_id)
    end

    # Creates the video hearing request
    def create_video_vacols_case(veteran, correspondent, judge)
      create(
        :case,
        :tied_to_judge,
        :video_hearing_requested,
        :type_cavc_remand,
        :ready_for_distribution,
        :status_active,
        tied_judge: judge,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation)
      )
    end

    # AC 2-6
    def create_ama_appeals
      APPEALS_LIMIT.times.each do
        create_ama_appeals_for_active_judge
        create_ama_appeals_for_inactive_cf_user_and_inactive_admin_judge_team
        create_ama_appeals_for_active_cf_user_and_non_admin_judge_team
        create_ama_appeals_for_active_cf_user_and_inactive_judge_team
      end
    end

    def create_ama_appeals_for_inactive_cf_user_and_inactive_admin_judge_team
      veteran = create_veteran_for_inactive_cf_user_and_inactive_admin_judge_team
      create_ama_appeals_ready_to_distribute_45_days(inactive_cf_user_and_inactive_admin_judge_team, veteran)
    end

    def create_ama_appeals_for_active_judge
      create_ama_appeals_ready_to_distribute_45_days(
        active_judge_hearing_affinity_45_days,
        create_veteran_for_active_judge
      )

      # For regression testing
      create_ama_appeals_ready_to_distribute_65_days(
        active_judge_hearing_affinity_65_days,
        create_veteran_for_active_judge
      )
    end

    def create_ama_appeals_for_active_cf_user_and_non_admin_judge_team
      veteran = create_veteran_for_active_cf_user_and_non_admin_judge_team
      create_ama_appeals_ready_to_distribute_45_days(active_cf_user_and_non_admin_judge_team, veteran)
    end

    def create_veteran_for_active_cf_user_and_non_admin_judge_team
      @active_cf_user_and_non_admin_judge_team_file_number += 1
      @active_cf_user_and_non_admin_judge_team_participant_id += 1
      create_veteran(
        file_number: @active_cf_user_and_non_admin_judge_team_file_number,
        participant_id: @active_cf_user_and_non_admin_judge_team_participant_id
      )
    end

    def create_ama_appeals_for_active_cf_user_and_inactive_judge_team
      veteran = create_veteran_for_active_cf_user_and_inactive_judge_team
      create_ama_appeals_ready_to_distribute_45_days(active_cf_user_and_inactive_judge_team, veteran)
    end

    def create_veteran_for_active_cf_user_and_inactive_judge_team
      @active_cf_user_and_inactive_judge_team_file_number += 1
      @active_cf_user_and_inactive_judge_team_participant_id += 1
      create_veteran(
        file_number: @active_cf_user_and_inactive_judge_team_file_number,
        participant_id: @active_cf_user_and_inactive_judge_team_participant_id
      )
    end

    # AC2,4,5,6: ready to distribute for less than 60 days
    def create_ama_appeals_ready_to_distribute_45_days(judge, veteran)
      Timecop.travel(45.days.ago)
      create(:appeal,
             :advanced_on_docket_due_to_motion,
             :hearing_docket,
             :with_post_intake_tasks,
             :held_hearing_and_ready_to_distribute,
             :with_request_issues,
             :with_appeal_affinity,
             issue_count: 1,
             tied_judge: judge,
             veteran: veteran,
             receipt_date: 2.years.ago)
      Timecop.return
    end

    # AC3: ready to distribute for more than 60 days
    def create_ama_appeals_ready_to_distribute_65_days(judge, veteran)
      Timecop.travel(65.days.ago)
      create(:appeal,
             :advanced_on_docket_due_to_motion,
             :hearing_docket,
             :with_post_intake_tasks,
             :held_hearing_and_ready_to_distribute,
             :with_request_issues,
             :with_appeal_affinity,
             issue_count: 1,
             tied_judge: judge,
             veteran: veteran,
             receipt_date: 2.years.ago)
      Timecop.return
    end
  end
end
