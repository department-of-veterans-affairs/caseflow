# frozen_string_literal: true

module Seeds
  class CasesTiedToJudgesNoLongerWithBoard < Base
    APPEALS_LIMIT = 50

    def initialize
      initialize_inactive_cf_user_and_inactive_admin_judge_team_file_number_and_participant_id
      initialize_active_cf_user_and_non_admin_judge_team_file_number_and_participant_id
      initialize_active_cf_user_and_inactive_judge_team_file_number_and_participant_id
      initialize_active_judge_file_number_and_participant_id
      initialize_active_cf_user_with_only_sattyid_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.find_by_css_id("CASEFLOW1")
      create_legacy_appeals
      create_ama_appeals
    end

    private

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def initialize_inactive_cf_user_and_inactive_admin_judge_team_file_number_and_participant_id
      @inactive_cf_user_and_inactive_admin_judge_team_file_number ||= 300_000_000
      @inactive_cf_user_and_inactive_admin_judge_team_participant_id ||= 400_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while find_veteran(@inactive_cf_user_and_inactive_admin_judge_team_file_number)
        @inactive_cf_user_and_inactive_admin_judge_team_file_number += 2000
        @inactive_cf_user_and_inactive_admin_judge_team_participant_id += 2000
      end
    end

    def initialize_active_cf_user_and_non_admin_judge_team_file_number_and_participant_id
      @active_cf_user_and_non_admin_judge_team_file_number ||= 301_000_000
      @active_cf_user_and_non_admin_judge_team_participant_id ||= 500_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while find_veteran(@active_cf_user_and_non_admin_judge_team_file_number)
        @active_cf_user_and_non_admin_judge_team_file_number += 2000
        @active_cf_user_and_non_admin_judge_team_participant_id += 2000
      end
    end

    def initialize_active_cf_user_and_inactive_judge_team_file_number_and_participant_id
      @active_cf_user_and_inactive_judge_team_file_number ||= 302_000_000
      @active_cf_user_and_inactive_judge_team_participant_id ||= 700_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while find_veteran(@active_cf_user_and_inactive_judge_team_file_number)
        @active_cf_user_and_inactive_judge_team_file_number += 2000
        @active_cf_user_and_inactive_judge_team_participant_id += 2000
      end
    end

    def initialize_active_judge_file_number_and_participant_id
      @file_number ||= 303_000_200
      @participant_id ||= 800_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while find_veteran(@file_number)
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def initialize_active_cf_user_with_only_sattyid_file_number_and_participant_id
      @active_cf_user_with_only_sattyid_file_number ||= 304_000_000
      @active_cf_user_with_only_sattyid_participant_id ||= 888_000_000
      while find_veteran(@active_cf_user_with_only_sattyid_file_number)
        @active_cf_user_with_only_sattyid_file_number += 2000
        @active_cf_user_with_only_sattyid_participant_id += 2000
      end
    end

    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }
      create(:veteran, params.merge(options))
    end

    def active_judge
      @active_judge ||= User.find_by(css_id: "BVAAABSHIRE")
    end

    def inactive_cf_user_and_inactive_admin_judge_team
      @inactive_cf_user_and_inactive_admin_judge_team ||= begin
        User.find_or_create_by(css_id: "BVADSLADER", station_id: 101).tap do |judge|
          judge.update!(status: "inactive", full_name: "BVADSLADER")
        end
      end
    end

    def active_cf_user_and_non_admin_judge_team
      @active_cf_user_and_non_admin_judge_team ||= create(:user, :with_non_admin_judge_team, :judge_role)
    end

    def active_cf_user_and_inactive_judge_team
      @active_cf_user_and_inactive_judge_team ||= create(:user, :with_inactive_judge_team, :judge_role)
    end

    def active_cf_user_with_only_sattyid
      @active_cf_user_with_only_sattyid ||= User.find_or_create_by(css_id: "BVAABERNIER")
    end

    def create_legacy_appeals
      Timecop.travel(65.days.ago)
      APPEALS_LIMIT.times.each do |offset|
        #{INACTIVE JUDGE AND ADMIN OF INACTIVE JUDGE TEAM}
        docket_number1 = "190000#{offset}"
        # Create the veteran for this legacy appeal
        veteran1 = create_veteran_for_inactive_cf_user_and_inactive_admin_judge_team

        # AC1: create legacy appeals ready to be distributed that have a hearing held by an inactive judge
        legacy_appeal1 = create_vacols_entries(veteran1, docket_number1, "RO17", inactive_cf_user_and_inactive_admin_judge_team)

        ## Hearing held by inactive judge
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: legacy_appeal1.vacols_id,
          user: inactive_cf_user_and_inactive_admin_judge_team
        )

        #{---------------------------------------------------------------------------------------------------------------}
        #{ACTIVE USER WITH ONLY SATTYID}
        docket_number2 = "190001#{offset}"
        # Create the veteran for this legacy appeal
        veteran2 = create_veteran_for_active_cf_user_with_only_sattyid

        #create legacy appeals ready to be distributed that have a hearing held by an active user with only sattyid
        legacy_appeal2 = create_vacols_entries(veteran2, docket_number2, "RO17", active_cf_user_with_only_sattyid)

        ## Hearing held by active user with only sattyid
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: legacy_appeal2.vacols_id,
          user: active_cf_user_with_only_sattyid
        )

         #{---------------------------------------------------------------------------------------------------------------}
        #{create legacy appeals ready to be distributed that have a hearing held by active_judge}
        docket_number3 = "190002#{offset}"
        # Create the veteran for this legacy appeal
        veteran3 = create_veteran_for_active_judge

        legacy_appeal3 = create_vacols_entries(veteran3, docket_number3, "RO17", active_judge)

        ## Hearing held by active judge
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: legacy_appeal3.vacols_id,
          user: active_judge
        )
      end
      Timecop.return
    end

    def create_veteran_for_inactive_cf_user_and_inactive_admin_judge_team
      @inactive_cf_user_and_inactive_admin_judge_team_file_number += 1
      @inactive_cf_user_and_inactive_admin_judge_team_participant_id += 1
      create_veteran(
        file_number: @inactive_cf_user_and_inactive_admin_judge_team_file_number,
        participant_id: @inactive_cf_user_and_inactive_admin_judge_team_participant_id
      )
    end

    def create_veteran_for_active_cf_user_with_only_sattyid
      @active_cf_user_with_only_sattyid_file_number += 1
      @active_cf_user_with_only_sattyid_participant_id += 1
      create_veteran(
        file_number: @active_cf_user_with_only_sattyid_file_number,
        participant_id: @active_cf_user_with_only_sattyid_participant_id
      )
    end

    def create_vacols_entries(veteran, docket_number, regional_office, user)
      vacols_folder = create(:folder, tinum: docket_number, titrnum: "#{veteran.file_number}S")
      correspondent = create(:correspondent, snamef: veteran.first_name, snamel: veteran.last_name, ssalut: "")
      # Create the judge
      if (user.css_id == "BVADSLADER")
        create(:staff, :inactive_judge, sdomainid: user.css_id)
      elsif (user.css_id == "BVAABERNIER")
        create(:staff, sdomainid: user.css_id)
      else
        create(:staff, :judge_role, sdomainid: user.css_id)
      end

      vacols_case = create_video_vacols_case(vacols_folder,
                                             correspondent,
                                             user)

      # Create the legacy_appeal, this doesn't fail with index problems, so no need to retry
      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )
      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      # Return the legacy_appeal
      legacy_appeal
    end

    # Creates the video hearing request
    def create_video_vacols_case(vacols_folder, correspondent, judge)
      create(
        :case,
        :assigned,
        :video_hearing_requested,
        :type_original,
        user: judge,
        correspondent: correspondent,
        bfcorlid: vacols_folder.titrnum,
        folder: vacols_folder,
        case_issues: create_list(:case_issue, 3, :compensation)
      )
    end

    # AC 2-6
    def create_ama_appeals
      create(:staff, :judge_role, sdomainid: active_cf_user_and_non_admin_judge_team.css_id)
      create(:staff, :judge_role, sdomainid: active_cf_user_and_inactive_judge_team.css_id)

      APPEALS_LIMIT.times.each do |_offset|
        create_ama_appeals_for_active_judge
        create_ama_appeals_for_inactive_cf_user_and_inactive_admin_judge_team
        create_ama_appeals_for_active_cf_user_and_non_admin_judge_team
        create_ama_appeals_for_active_cf_user_and_inactive_judge_team
      end
    end

    def create_ama_appeals_for_inactive_cf_user_and_inactive_admin_judge_team
      veteran = create_veteran_for_inactive_cf_user_and_inactive_admin_judge_team
      create_ama_appeals_ready_to_distribute_less_than_60_days(inactive_cf_user_and_inactive_admin_judge_team, veteran)
    end

    def create_ama_appeals_for_active_judge
      veteran = create_veteran_for_active_judge
      create_ama_appeals_ready_to_distribute_less_than_60_days(active_judge, veteran)

      veteran = create_veteran_for_active_judge
      create_ama_appeals_ready_to_distribute_more_than_60_days(active_judge, veteran)
    end

    def create_veteran_for_active_judge
      @file_number += 1
      @participant_id += 1
      create_veteran(file_number: @file_number, participant_id: @participant_id)
    end

    def create_ama_appeals_for_active_cf_user_and_non_admin_judge_team
      veteran = create_veteran_for_active_cf_user_and_non_admin_judge_team
      create_ama_appeals_ready_to_distribute_less_than_60_days(active_cf_user_and_non_admin_judge_team, veteran)
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
      create_ama_appeals_ready_to_distribute_less_than_60_days(active_cf_user_and_inactive_judge_team, veteran)
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
    def create_ama_appeals_ready_to_distribute_less_than_60_days(judge, veteran)
      Timecop.travel(1.day.ago)
      create(:appeal,
             :advanced_on_docket_due_to_motion,
             :with_post_intake_tasks,
             :held_hearing_and_ready_to_distribute,
             :hearing_docket,
             tied_judge: judge,
             veteran: veteran,
             receipt_date: 2.years.ago)
      Timecop.return
    end

    # AC3: ready to distribute for more than 60 days
    def create_ama_appeals_ready_to_distribute_more_than_60_days(judge, veteran)
      Timecop.travel(61.days.ago)
      create(:appeal,
             :with_post_intake_tasks,
             :held_hearing_and_ready_to_distribute,
             :hearing_docket,
             tied_judge: judge,
             veteran: veteran,
             receipt_date: 2.years.ago)
      Timecop.return
    end
  end
end
