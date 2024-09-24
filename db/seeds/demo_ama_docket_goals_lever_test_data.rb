# frozen_string_literal: true

module Seeds
  class DemoAmaDocketGoalsLeverTestData < Base
    def initialize
      initialize_ev_sub_np_dockets_file_number_and_participant_id
      initialize_ev_sub_prior_dockets_file_number_and_participant_id
      initialize_dr_np_dockets_file_number_and_participant_id
      initialize_dr_prior_dockets_file_number_and_participant_id
      initialize_hearings_np_dockets_file_number_and_participant_id
      initialize_hearings_prior_dockets_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_judges
      create_dockets
    end

    private
    def create_judges
      find_or_create_judge("BVADCremin", "Daija K Cremin")
      find_or_create_inactive_judge("IneligJudge", "Ineligible JudgeAA")
    end

    def create_dockets
      create_evidence_submission_non_priority_dockets
      create_evidence_submission_priority_dockets
      create_direct_review_non_priority_dockets
      create_direct_review_priority_dockets
      create_hearings_non_priority_dockets
      create_hearings_priority_dockets
    end

    def create_evidence_submission_non_priority_dockets
      evidence_sub_np_reciept_days_ago_list = [
        700, 699, 697, 613, 612, 611, 475, 474, 473, 437, 436, 435, 110, 109, 108, 93, 92, 91, 90, 51, 50
      ]

      evidence_sub_np_reciept_days_ago_list.each do |days|
        create_evidence_submission_non_priority_docket(days.days.ago)
      end
    end

    def create_evidence_submission_priority_dockets
      evidence_sub_priority_reciept_days_ago_list = [
        20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 1
      ]

      evidence_sub_priority_reciept_days_ago_list.each do |days|
        create_evidence_submission_priority_docket(days.days.ago)
      end
    end

    def create_direct_review_non_priority_dockets
      direct_rev_np_reciept_days_ago_list = [
        600, 599, 598, 435, 434, 432, 290, 289, 288, 272, 271, 270, 110, 109, 108, 53, 52, 51, 50, 21, 20
      ]

      direct_rev_np_reciept_days_ago_list.each do |days|
        create_direct_review_non_priority_docket(days.days.ago)
      end
    end

    def create_direct_review_priority_dockets
      direct_rev_np_reciept_days_ago_list = [
        21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
      ]

      direct_rev_np_reciept_days_ago_list.each do |days|
        create_direct_review_priority_docket(days.days.ago)
      end
    end

    def create_hearings_non_priority_dockets
      ineligible_judge_non_prior_ago_list = [
        1000, 900, 880, 840, 830, 820, 650, 644, 630, 630, 630, 630, 550, 540, 530, 520, 510, 500, 300, 200, 100
      ]
      cremin_judge_non_prior_ago_list = [
        1000, 900, 650, 644, 530, 520, 100
      ]

      ineligible_judge_non_prior_ago_list.each do |days|
        create_hearings_non_priority_docket(days.days.ago, find_judge("IneligJudge"))
      end
      cremin_judge_non_prior_ago_list.each do |days|
        create_hearings_non_priority_docket(days.days.ago, find_judge("BVADCremin"))
      end
    end

    def create_hearings_priority_dockets
      cremin_judge_non_prior_ago_list = [
        100, 300, 500
      ]

      cremin_judge_non_prior_ago_list.each do |days|
        create_hearings_priority_docket(days.days.ago, find_judge("BVADCremin"))
      end
    end

    # Functions of Judge and Veteran
    def find_or_create_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_inactive_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_inactive_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_judge(css_id)
      User.find_by_css_id(css_id)
    end

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }

      Veteran.find_by_participant_id(params[:participant_id]) || create(:veteran, params.merge(options))
    end

    # Initialization functions
    def initialize_ev_sub_np_dockets_file_number_and_participant_id
      @evidence_submission_np_file_number ||= 700_100_000
      @evidence_submission_np_participant_id ||= 700_120_000

      while find_veteran(@evidence_submission_np_file_number)
        @evidence_submission_np_file_number += 2000
        @evidence_submission_np_participant_id += 2000
      end
    end

    def initialize_ev_sub_prior_dockets_file_number_and_participant_id
      @evidence_submission_prior_file_number ||= 700_200_000
      @evidence_submission_prior_participant_id ||= 700_220_000

      while find_veteran(@evidence_submission_prior_file_number)
        @evidence_submission_prior_file_number += 2000
        @evidence_submission_prior_participant_id += 2000
      end
    end

    def initialize_dr_np_dockets_file_number_and_participant_id
      @direct_review_np_file_number ||= 700_300_000
      @direct_review_np_participant_id ||= 700_320_000

      while find_veteran(@direct_review_np_file_number)
        @direct_review_np_file_number += 2000
        @direct_review_np_participant_id += 2000
      end
    end

    def initialize_dr_prior_dockets_file_number_and_participant_id
      @direct_review_prior_file_number ||= 700_400_000
      @direct_review_prior_participant_id ||= 700_420_000

      while find_veteran(@direct_review_prior_file_number)
        @direct_review_prior_file_number += 2000
        @direct_review_prior_participant_id += 2000
      end
    end

    def initialize_hearings_np_dockets_file_number_and_participant_id
      @hearings_np_file_number ||= 700_500_000
      @hearings_np_participant_id ||= 700_520_000

      while find_veteran(@hearings_np_file_number)
        @hearings_np_file_number += 2000
        @hearings_np_participant_id += 2000
      end
    end

    def initialize_hearings_prior_dockets_file_number_and_participant_id
      @hearings_prior_file_number ||= 700_600_000
      @hearings_prior_participant_id ||= 700_620_000

      while find_veteran(@hearings_prior_file_number)
        @hearings_prior_file_number += 2000
        @hearings_prior_participant_id += 2000
      end
    end

    # Docket Creation Functions

    # Direct Evidence Submission Creation Functions
    def create_evidence_submission_non_priority_docket(days_ago)
      Timecop.travel(days_ago)
      create(
        :appeal,
        :evidence_submission_docket,
        :ready_for_distribution,
        veteran: create_veteran_for_evidence_submission_non_priority,
        receipt_date: days_ago
      )
      Timecop.return
    end

    def create_veteran_for_evidence_submission_non_priority
      @evidence_submission_np_file_number += 1
      @evidence_submission_np_participant_id += 1
      create_veteran(
        file_number: @evidence_submission_np_file_number,
        participant_id: @evidence_submission_np_participant_id
      )
    end

    def create_evidence_submission_priority_docket(days_ago)
      Timecop.travel(days_ago)
      create(
        :appeal,
        :evidence_submission_docket,
        :ready_for_distribution,
        :advanced_on_docket_due_to_age,
        veteran: create_veteran_for_evidence_submission_priority,
        receipt_date: days_ago
      )
      Timecop.return
    end

    def create_veteran_for_evidence_submission_priority
      @evidence_submission_prior_file_number += 1
      @evidence_submission_prior_participant_id += 1
      create_veteran(
        file_number: @evidence_submission_prior_file_number,
        participant_id: @evidence_submission_prior_participant_id
      )
    end

    # Direct Review Docket Creation Functions
    def create_direct_review_non_priority_docket(days_ago)
      Timecop.travel(days_ago)
      create(
        :appeal,
        :direct_review_docket,
        :ready_for_distribution,
        veteran: create_veteran_for_direct_review_non_priority,
        receipt_date: days_ago
      )
      Timecop.return
    end

    def create_veteran_for_direct_review_non_priority
      @direct_review_np_file_number += 1
      @direct_review_np_participant_id += 1
      create_veteran(
        file_number: @direct_review_np_file_number,
        participant_id: @direct_review_np_participant_id
      )
    end

    def create_direct_review_priority_docket(days_ago)
      Timecop.travel(days_ago)
      create(
        :appeal,
        :direct_review_docket,
        :ready_for_distribution,
        :advanced_on_docket_due_to_age,
        veteran: create_veteran_for_direct_review_priority,
        receipt_date: days_ago
      )
      Timecop.return
    end

    def create_veteran_for_direct_review_priority
      @direct_review_prior_file_number += 1
      @direct_review_prior_participant_id += 1
      create_veteran(
        file_number: @direct_review_prior_file_number,
        participant_id: @direct_review_prior_participant_id
      )
    end

    # Hearing Docket Creation Functions
    def create_hearings_non_priority_docket(days_ago, judge)
      Timecop.travel(days_ago)
      create(
        :appeal,
        :hearing_docket,
        :with_post_intake_tasks,
        :held_hearing_and_ready_to_distribute,
        :tied_to_judge,
        veteran: create_veteran_for_hearing_non_priority,
        receipt_date: days_ago,
        tied_judge: judge,
        adding_user: User.first
      )
      Timecop.return
    end

    def create_veteran_for_hearing_non_priority
      @hearings_np_file_number += 1
      @hearings_np_participant_id += 1
      create_veteran(
        file_number: @hearings_np_file_number,
        participant_id: @hearings_np_participant_id
      )
    end

    def create_hearings_priority_docket(days_ago, judge)
      Timecop.travel(days_ago)
      create(
        :appeal,
        :hearing_docket,
        :with_post_intake_tasks,
        :advanced_on_docket_due_to_age,
        :held_hearing_and_ready_to_distribute,
        :tied_to_judge,
        veteran: create_veteran_for_hearing_priority,
        receipt_date: days_ago,
        tied_judge: judge,
        adding_user: User.first
      )
      Timecop.return
    end

    def create_veteran_for_hearing_priority
      @hearings_prior_file_number += 1
      @hearings_prior_participant_id += 1
      create_veteran(
        file_number: @hearings_prior_file_number,
        participant_id: @hearings_prior_participant_id
      )
    end
  end
end
