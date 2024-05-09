# frozen_string_literal: true

module Seeds
  class DemoAodHearingCaseLeverTestData < Base
    def initialize
      initialize_ama_hearing_held_aod_cavc_file_number_and_participant_id
      initialize_ama_hearing_held_aod_file_number_and_participant_id
      initialize_ama_hearing_held_cavc_file_number_and_participant_id
      initialize_ama_hearing_held_file_number_and_participant_id
      initialize_direct_review_file_number_and_participant_id
      @receipt_date = 25.years.ago
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_judges
      create_appeals
    end

    private
    def create_judges
      find_or_create_judge("AMAAODCAVC", "AMA AOD CAVC")
      find_or_create_judge("AMACAVC", "AMA CAVC")
      find_or_create_judge("AMANonPri", "AMA Non-priority")
      find_or_create_judge("EligJudge20days", "EligibleJudge 20Days")
      find_or_create_judge("EligJudge6days", "EligibleJudge 6Days")
      find_or_create_judge("EligJudge5Days", "EligibleJudge 5Days")
      find_or_create_inactive_judge("IneligJudgeAA", "Ineligible JudgeAA")
      find_or_create_inactive_judge("IneligJudgeBB", "Ineligible JudgeBB")
      find_or_create_inactive_judge("NotHearingDocket", "Inactive DirectReview Judge")
      find_or_create_attorney("CAVCATNY", "CAVC Attorney")
    end

    def create_appeals
      # 2 | AMA hearings + AOD + CAVC | AMAAODCAVC | 395 days
      create_ama_hearing_held_aod_cavc_appeals(2, find_judge("AMAAODCAVC"), 395.days.ago, 20.years.ago)
      # 2 | AMA hearings + CAVC | AMACAVC | 395 days
      create_ama_hearing_held_cavc_appeals(2, find_judge("AMACAVC"), 395.days.ago, 20.years.ago)
      # 24 | AMA hearing | AMANonPri, BVAABode | 395 days
      create_ama_hearing_held_appeals(12, find_judge("AMANonPri"), 395.days.ago, 20.years.ago)
      create_ama_hearing_held_appeals(12, find_judge("BVAABode"), 395.days.ago, 20.years.ago)
      # 12 | AMA AOD Hearings tied to judges no longer w board | need names of ppl in ineligible judges list or need to create an ineligible judge (if create, name them IneligListJudge) | 399 days
      create_ama_hearing_held_aod_appeals(6, find_inactive_judge("IneligJudgeAA"), 399.days.ago, 20.years.ago)
      create_ama_hearing_held_aod_appeals(6, find_inactive_judge("IneligJudgeBB"), 399.days.ago, 20.years.ago)
      # 12 | AMA AOD hearings tied to judges with checkbox checked | BVAAAbshire | 400 days
      create_ama_hearing_held_aod_appeals(12, find_judge("BVAAAbshire"), 400.days.ago, 20.years.ago)
      # 12 | AMA AOD hearings tied to a tester's judge | BVAEEmard (Evangeline)BVACOTBjudge | 399 days
      create_ama_hearing_held_aod_appeals(6, find_judge("BVAEEmard"), 399.days.ago, 20.years.ago)
      create_ama_hearing_held_aod_appeals(6, find_judge("BVACOTBjudge"), 399.days.ago, 20.years.ago)
      # 20 | AMA AOD hearing tied to judge that is not a test judge with RTD date 20 days | EligJudge20days | 20 days
      create_ama_hearing_held_aod_appeals(20, find_judge("EligJudge20days"), 20.days.ago, 20.years.ago)
      # 2 | AMA AOD hearing to judge that is not a test judge with RTD date 20 days | BVAAAbshire | 20 days
      create_ama_hearing_held_aod_appeals(2, find_judge("BVAAAbshire"), 20.days.ago, 20.years.ago)
      # 16 | AMA AOD hearing tied to judge that is not a test judge with RTD date 5 days | EligJudge6days, BVAEBecker | 5 days
      create_ama_hearing_held_aod_appeals(8, find_judge("EligJudge6days"), 5.days.ago, 20.years.ago)
      create_ama_hearing_held_aod_appeals(8, find_judge("BVAEBecker"), 5.days.ago, 20.years.ago)
      # 36 | AMA AOD hearing tied to judge that is not a test judge with RTD date 5 days | BVAAbode, BVABDaniel | 5 days
      create_ama_hearing_held_aod_appeals(18, find_judge("BVAAbode"), 5.days.ago, 20.years.ago)
      create_ama_hearing_held_aod_appeals(18, find_judge("BVABDaniel"), 5.days.ago, 20.years.ago)
      # 36 | AMA AOD hearing Tied to a non-tester judge with 5 days rtd | EligJudge5Days | 5 days
      create_ama_hearing_held_aod_appeals(36, find_judge("EligJudge5Days"), 5.days.ago, 20.years.ago)
      # 30 | Evidence Submission or Direct Review (Developers choice) | NotHearingDocket | 10 days
      create_direct_review_appeals(30, find_judge("NotHearingDocket"), 10.days.ago, 20.years.ago)
    end

    def create_ama_hearing_held_aod_cavc_appeals(number_of_appeals_to_create, hearing_judge, appeal_affinity_start_date, receipt_date)
      number_of_appeals_to_create.times.each do
        create_ama_hearing_held_aod_cavc_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      end
    end

    def create_ama_hearing_held_aod_appeals(number_of_appeals_to_create, hearing_judge, appeal_affinity_start_date, receipt_date)
      number_of_appeals_to_create.times.each do
        create_ama_hearing_held_aod_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      end
    end

    def create_ama_hearing_held_cavc_appeals(number_of_appeals_to_create, hearing_judge, appeal_affinity_start_date, receipt_date)
      number_of_appeals_to_create.times.each do
        create_ama_hearing_held_cavc_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      end
    end

    def create_ama_hearing_held_appeals(number_of_appeals_to_create, hearing_judge, appeal_affinity_start_date, receipt_date)
      number_of_appeals_to_create.times.each do
        create_ama_hearing_held_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      end
    end

    def create_direct_review_appeals(number_of_appeals_to_create, associated_judge, appeal_affinity_start_date, receipt_date)
      number_of_appeals_to_create.times.each do
        create_direct_review_appeal(associated_judge, appeal_affinity_start_date, receipt_date)
      end
    end

    # Functions of Judge Creation
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

    def find_inactive_judge(css_id)
      User.find_by_css_id(css_id)
    end

    def find_or_create_attorney(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :with_vacols_attorney_record, css_id: css_id, full_name: full_name)
    end

    def find_attorney(css_id)
      User.find_by_css_id(css_id)
    end

    #Functions for Initialization
    def initialize_ama_hearing_held_aod_cavc_file_number_and_participant_id
      @ama_hearing_held_aod_cavc_file_number ||= 702_000_200
      @ama_hearing_held_aod_cavc_participant_id ||= 712_000_000

      while find_veteran(@ama_hearing_held_aod_cavc_file_number)
        @ama_hearing_held_aod_cavc_file_number += 2000
        @ama_hearing_held_aod_cavc_participant_id += 2000
      end
    end

    def initialize_ama_hearing_held_aod_file_number_and_participant_id
      @ama_hearing_held_aod_file_number ||= 706_000_600
      @ama_hearing_held_aod_participant_id ||= 716_000_000

      while find_veteran(@ama_hearing_held_aod_file_number)
        @ama_hearing_held_aod_file_number += 2000
        @ama_hearing_held_aod_participant_id += 2000
      end
    end

    def initialize_ama_hearing_held_cavc_file_number_and_participant_id
      @ama_hearing_held_cavc_file_number ||= 710_001_000
      @ama_hearing_held_cavc_participant_id ||= 720_000_000

      while find_veteran(@ama_hearing_held_cavc_file_number)
        @ama_hearing_held_cavc_file_number += 2000
        @ama_hearing_held_cavc_participant_id += 2000
      end
    end

    def initialize_ama_hearing_held_file_number_and_participant_id
      @ama_hearing_held_file_number ||= 714_001_400
      @ama_hearing_held_participant_id ||= 724_000_000

      while find_veteran(@ama_hearing_held_file_number)
        @ama_hearing_held_file_number += 2000
        @ama_hearing_held_participant_id += 2000
      end
    end

    def initialize_direct_review_file_number_and_participant_id
      @direct_review_file_number ||= 718_001_800
      @direct_review_participant_id ||= 728_000_000

      while find_veteran(@direct_review_file_number)
        @direct_review_file_number += 2000
        @direct_review_participant_id += 2000
      end
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

    # Appeal Creation Functions
    # AMA Hearing Held AOD and CAVC appeal creation functions
    def create_ama_hearing_held_aod_cavc_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      Timecop.travel(appeal_affinity_start_date + 1.day)
        ama_hearing_aod_cavc_appeal= create(
          :appeal,
          :hearing_docket,
          :held_hearing,
          :tied_to_judge,
          :advanced_on_docket_due_to_age,
          :dispatched,
          veteran: create_veteran_for_ama_hearing_held_aod_cavc_judge,
          receipt_date: receipt_date,
          tied_judge: hearing_judge,
          associated_judge: hearing_judge,
          adding_user: User.first,
          associated_attorney: find_attorney("CAVCATNY")
        )
      Timecop.return
      Timecop.travel(appeal_affinity_start_date)
        remand = create(:cavc_remand, source_appeal: ama_hearing_aod_cavc_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
      Timecop.return
    end

    def create_veteran_for_ama_hearing_held_aod_cavc_judge
      @ama_hearing_held_aod_cavc_file_number += 1
      @ama_hearing_held_aod_cavc_participant_id += 1
      create_veteran(
        file_number: @ama_hearing_held_aod_cavc_file_number,
        participant_id: @ama_hearing_held_aod_cavc_participant_id
      )
    end

    def create_attorney_for_ama_hearing_held_aod_cavc

    end

    # AMA Hearing Held AOD appeal creation functions
    def create_ama_hearing_held_aod_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      Timecop.travel(appeal_affinity_start_date)
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing_and_ready_to_distribute,
          :tied_to_judge,
          :with_appeal_affinity,
          veteran: create_veteran_for_ama_hearing_held_aod_judge,
          receipt_date: receipt_date,
          tied_judge: hearing_judge,
          adding_user: User.first
        )
      Timecop.return
    end

    def create_veteran_for_ama_hearing_held_aod_judge
      @ama_hearing_held_aod_file_number += 1
      @ama_hearing_held_aod_participant_id += 1
      create_veteran(
        file_number: @ama_hearing_held_aod_file_number,
        participant_id: @ama_hearing_held_aod_participant_id
      )
    end

    # AMA Hearing Held CAVC appeal creation functions
    def create_ama_hearing_held_cavc_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      Timecop.travel(appeal_affinity_start_date + 1.day)
        ama_hearing_cavc_appeal = create(
          :appeal,
          :hearing_docket,
          :held_hearing,
          :tied_to_judge,
          :dispatched,
          veteran: create_veteran_for_ama_hearing_held_aod_cavc_judge,
          receipt_date: receipt_date,
          tied_judge: hearing_judge,
          associated_judge: hearing_judge,
          adding_user: User.first,
          associated_attorney: find_attorney("CAVCATNY")
        )
      Timecop.return
      Timecop.travel(appeal_affinity_start_date)
        remand = create(:cavc_remand, source_appeal: ama_hearing_cavc_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
      Timecop.return
    end

    def create_veteran_for_ama_hearing_held_cavc_judge
      @ama_hearing_held_cavc_file_number += 1
      @ama_hearing_held_cavc_participant_id += 1
      create_veteran(
        file_number: @ama_hearing_held_cavc_file_number,
        participant_id: @ama_hearing_held_cavc_participant_id
      )
    end

    # AMA Hearing Held Non-AOD, Non-CAVC appeal creation functions
    def create_ama_hearing_held_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      Timecop.travel(appeal_affinity_start_date)
        create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
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

    # Direct review appeal creation functions
    def create_direct_review_appeal(associated_judge, appeal_affinity_start_date, receipt_date)
      Timecop.travel(appeal_affinity_start_date)
      create(
        :appeal,
        :direct_review_docket,
        :ready_for_distribution,
        associated_judge: associated_judge,
        veteran: create_veteran_for_direct_review,
        receipt_date: receipt_date
      )
      Timecop.return
    end

    def create_veteran_for_direct_review
      @direct_review_file_number += 1
      @direct_review_participant_id += 1
      create_veteran(file_number: @direct_review_file_number, participant_id: @direct_review_participant_id)
    end

  end
end
