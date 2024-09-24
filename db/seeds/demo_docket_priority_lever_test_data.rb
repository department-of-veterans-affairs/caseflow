# frozen_string_literal: true

module Seeds
  class DemoDocketPriorityLeverTestData < Base
    def initialize
      initialize_docket_seeds_lists
      initialize_ev_sub_np_dockets_file_number_and_participant_id
      initialize_ev_sub_prior_dockets_file_number_and_participant_id
      initialize_dr_np_dockets_file_number_and_participant_id
      initialize_dr_prior_dockets_file_number_and_participant_id
      initialize_hearings_np_dockets_file_number_and_participant_id
      initialize_hearings_prior_dockets_file_number_and_participant_id
      initialize_cavc_legacy_np_dockets_file_number_and_participant_id
      initialize_cavc_legacy_prior_dockets_file_number_and_participant_id
      initialize_cavc_hearing_np_dockets_file_number_and_participant_id
      initialize_cavc_hearing_prior_dockets_file_number_and_participant_id
      initialize_legacy_np_dockets_file_number_and_participant_id
      initialize_legacy_prior_dockets_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_judges
      create_dockets
    end

    private
    def create_judges
      find_or_create_judge("BVADCremin", "Daija K Cremin")
      find_or_create_judge("BVAKKEELING", "Keith Judge_CaseToAssign_NoTeam Keeling" )
      find_or_create_judge("BVACOTBJudge", "Judith COTB Judge" )
      find_or_create_inactive_judge("IneligJudge", "Ineligible JudgeAA")
      find_or_create_attorney("CAVCATNY", "CAVC Attorney")
    end

    def create_dockets
      create_evidence_submission_non_priority_dockets
      create_evidence_submission_priority_dockets
      create_direct_review_non_priority_dockets
      create_direct_review_priority_dockets
      create_hearings_non_priority_dockets
      create_hearings_priority_dockets
      create_legacy_non_priority_dockets
      create_legacy_priority_dockets
    end

    def initialize_docket_seeds_lists
      @evidence_sub_np_reciept_days_ago_list = [700, 699, 697, 613, 612, 611, 475, 474, 473, 437, 436, 435, 200, 199, 198, 197, 196, 195, 194, 193]
      @evidence_sub_prior_reciept_days_ago_list = [100, 99, 98, 97, 55, 54, 53, 49, 48, 80, 99, 98, 97, 55, 54, 53, 49, 48, 80, 77]
      @direct_rev_np_reciept_days_ago_list = [700, 699, 697, 613, 612, 611, 475, 474, 473, 437, 436, 435, 200, 199, 198, 197, 196, 195, 194, 193]
      @direct_rev_prior_reciept_days_ago_list = [100, 99, 98, 97, 55, 54, 53, 49, 48, 80, 99, 98, 97, 55, 54, 53, 49, 48, 80, 77]
      @hearings_ineligible_judge_np_days_ago_list = [700, 699, 697, 613, 612, 611, 475, 474, 473, 437, 436, 435, 200, 199, 198, 197, 196, 195, 194, 193]
      @hearings_cremin_np_days_ago_list = [700, 699, 697, 613, 612, 611, 475, 474, 473, 437]
      @hearings_ineligible_judge_prior_days_ago_list = [700, 699, 697, 613, 612, 611, 475, 474, 473, 437, 436, 435, 200, 199, 198, 197, 196, 195, 194, 193]
      @hearings_cremin_prior_days_ago_list = [700, 699, 697, 613, 612, 611, 475, 474, 473, 437]
      @cavc_legacy_np_keeling_days_ago_list = [600]
      @cavc_legacy_prior_keeling_days_ago_list = [60]
      @cavc_ama_hearing_np_keeling_days_ago_list = [600]
      @cavc_ama_hearing_prior_keeling_days_ago_list = [60]
      @legacy_np_ineligible_judge_days_ago_list = [4082, 3000, 2000, 1888, 1800, 1500, 1400, 1200, 1000, 997]
      @legacy_prior_ineligible_judge_days_ago_list = [100, 99, 98, 97, 55, 54, 53, 49, 48, 80]
      @legacy_np_BVACOTBJudge_days_ago_list = [3800, 2800, 1900, 1877, 1760, 1479, 1300, 1100, 999, 998]
      @legacy_prior_BVACOTBJudge_days_ago_list = [99, 98, 97, 55, 54, 53, 49, 48, 80, 77]
    end


    def create_evidence_submission_non_priority_dockets
      @evidence_sub_np_reciept_days_ago_list.each do |days|
        create_evidence_submission_non_priority_docket(days.days.ago)
      end
    end

    def create_evidence_submission_priority_dockets
      @evidence_sub_prior_reciept_days_ago_list.each do |days|
        create_evidence_submission_priority_docket(days.days.ago)
      end
    end

    def create_direct_review_non_priority_dockets
      @direct_rev_np_reciept_days_ago_list.each do |days|
        create_direct_review_non_priority_docket(days.days.ago)
      end
    end

    def create_direct_review_priority_dockets
      @direct_rev_prior_reciept_days_ago_list.each do |days|
        create_direct_review_priority_docket(days.days.ago)
      end
    end

    def create_hearings_non_priority_dockets
      @hearings_ineligible_judge_np_days_ago_list.each do |days|
        create_hearings_non_priority_docket(days.days.ago, find_judge("IneligJudge"))
      end
      @hearings_cremin_np_days_ago_list.each do |days|
        create_hearings_non_priority_docket(days.days.ago, find_judge("BVADCremin"))
      end
    end

    def create_hearings_priority_dockets
      @hearings_ineligible_judge_prior_days_ago_list.each do |days|
        create_hearings_priority_docket(days.days.ago, find_judge("IneligJudge"))
      end
      @hearings_cremin_prior_days_ago_list.each do |days|
        create_hearings_priority_docket(days.days.ago, find_judge("BVADCremin"))
      end
    end

    def create_cavc_legacy_non_priority_dockets
      @cavc_legacy_np_keeling_days_ago_list.each do |days|
        create_cavc_legacy_non_priority_dockets(days.days.ago, find_judge("BVAKKEELING"))
      end
    end

    def create_cavc_legacy_priority_dockets
      @cavc_legacy_prior_keeling_days_ago_list.each do |days|
        create_cavc_legacy_priority_dockets(days.days.ago, find_judge("BVAKKEELING"))
      end
    end

    def create_cavc_hearing_non_priority_dockets
      @cavc_ama_hearing_np_keeling_days_ago_list.each do |days|
        create_cavc_hearing_non_priority_docket(days.days.ago, find_judge("BVAKKEELING"))
      end
    end

    def create_cavc_hearing_priority_dockets
      @cavc_ama_hearing_prior_keeling_days_ago_list.each do |days|
        create_cavc_hearing_priority_docket(days.days.ago, find_judge("BVAKKEELING"))
      end
    end

    def create_legacy_non_priority_dockets
      @legacy_np_ineligible_judge_days_ago_list.each do |days|
        create_legacy_non_priority_docket(days.days.ago, find_judge("IneligJudge"))
      end
      @legacy_np_BVACOTBJudge_days_ago_list.each do |days|
        create_legacy_non_priority_docket(days.days.ago, find_judge("BVACOTBJudge"))
      end
    end

    def create_legacy_priority_dockets
      @legacy_prior_ineligible_judge_days_ago_list.each do |days|
        create_legacy_priority_docket(days.days.ago, find_judge("IneligJudge"))
      end
      @legacy_prior_BVACOTBJudge_days_ago_list.each do |days|
        create_legacy_priority_docket(days.days.ago, find_judge("BVACOTBJudge"))
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

    def find_or_create_attorney(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :with_vacols_attorney_record, css_id: css_id, full_name: full_name)
    end

    def find_attorney(css_id)
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

    def regional_office
      'RO17'
    end

    # Initialization functions
    def initialize_ev_sub_np_dockets_file_number_and_participant_id
      @evidence_submission_np_file_number ||= 700_150_000
      @evidence_submission_np_participant_id ||= 700_170_000

      while find_veteran(@evidence_submission_np_file_number)
        @evidence_submission_np_file_number += 2000
        @evidence_submission_np_participant_id += 2000
      end
    end

    def initialize_ev_sub_prior_dockets_file_number_and_participant_id
      @evidence_submission_prior_file_number ||= 700_250_000
      @evidence_submission_prior_participant_id ||= 700_270_000

      while find_veteran(@evidence_submission_prior_file_number)
        @evidence_submission_prior_file_number += 2000
        @evidence_submission_prior_participant_id += 2000
      end
    end

    def initialize_dr_np_dockets_file_number_and_participant_id
      @direct_review_np_file_number ||= 700_350_000
      @direct_review_np_participant_id ||= 700_370_000

      while find_veteran(@direct_review_np_file_number)
        @direct_review_np_file_number += 2000
        @direct_review_np_participant_id += 2000
      end
    end

    def initialize_dr_prior_dockets_file_number_and_participant_id
      @direct_review_prior_file_number ||= 700_450_000
      @direct_review_prior_participant_id ||= 700_470_000

      while find_veteran(@direct_review_prior_file_number)
        @direct_review_prior_file_number += 2000
        @direct_review_prior_participant_id += 2000
      end
    end

    def initialize_hearings_np_dockets_file_number_and_participant_id
      @hearings_np_file_number ||= 700_550_000
      @hearings_np_participant_id ||= 700_570_000

      while find_veteran(@hearings_np_file_number)
        @hearings_np_file_number += 2000
        @hearings_np_participant_id += 2000
      end
    end

    def initialize_hearings_prior_dockets_file_number_and_participant_id
      @hearings_prior_file_number ||= 700_650_000
      @hearings_prior_participant_id ||= 700_670_000

      while find_veteran(@hearings_prior_file_number)
        @hearings_prior_file_number += 2000
        @hearings_prior_participant_id += 2000
      end
    end

    def initialize_cavc_legacy_np_dockets_file_number_and_participant_id
      @cavc_legacy_np_file_number ||= 700_650_000
      @cavc_legacy_np_participant_id ||= 700_670_000

      while find_veteran(@cavc_legacy_np_file_number)
        @cavc_legacy_np_file_number += 2000
        @cavc_legacy_np_participant_id += 2000
      end
    end

    def initialize_cavc_legacy_prior_dockets_file_number_and_participant_id
      @cavc_legacy_prior_file_number ||= 700_650_000
      @cavc_legacy_prior_participant_id ||= 700_670_000

      while find_veteran(@cavc_legacy_prior_file_number)
        @cavc_legacy_prior_file_number += 2000
        @cavc_legacy_prior_participant_id += 2000
      end
    end

    def initialize_cavc_hearing_np_dockets_file_number_and_participant_id
      @cavc_hearing_np_file_number ||= 700_650_000
      @cavc_hearing_np_participant_id ||= 700_670_000

      while find_veteran(@cavc_hearing_np_file_number)
        @cavc_hearing_np_file_number += 2000
        @cavc_hearing_np_participant_id += 2000
      end
    end

    def initialize_cavc_hearing_prior_dockets_file_number_and_participant_id
      @cavc_hearing_prior_file_number ||= 700_650_000
      @cavc_hearing_prior_participant_id ||= 700_670_000

      while find_veteran(@cavc_hearing_prior_file_number)
        @cavc_hearing_prior_file_number += 2000
        @cavc_hearing_prior_participant_id += 2000
      end
    end

    def initialize_legacy_np_dockets_file_number_and_participant_id
      @legacy_np_file_number ||= 700_650_000
      @legacy_np_participant_id ||= 700_670_000

      while find_veteran(@legacy_np_file_number)
        @legacy_np_file_number += 2000
        @legacy_np_participant_id += 2000
      end
    end

    def initialize_legacy_prior_dockets_file_number_and_participant_id
      @legacy_prior_file_number ||= 700_650_000
      @legacy_prior_participant_id ||= 700_670_000

      while find_veteran(@legacy_prior_file_number)
        @legacy_prior_file_number += 2000
        @legacy_prior_participant_id += 2000
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

    # CAVC Legacy Creation Functions
    def create_cavc_legacy_non_priority_docket(days_ago, judge)
    Timecop.travel(days_ago + 1.day)
      veteran = create_veteran_for_cavc_legacy_non_priority

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_non_aod_video_vacols_case(veteran,
                                            correspondent,
                                            judge,
                                            days_ago)

      cavc_legacy_non_priority_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: cavc_legacy_non_priority_appeal)
      Timecop.return
      Timecop.travel(days_ago)
        remand = create(:cavc_remand, source_appeal: cavc_legacy_non_priority_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      Timecop.return
    end

    def create_veteran_for_cavc_legacy_non_priority
      @cavc_legacy_np_file_number += 1
      @cavc_legacy_np_participant_id += 1
      create_veteran(
        file_number: @cavc_legacy_np_file_number,
        participant_id: @cavc_legacy_np_participant_id
      )
    end

    def create_cavc_legacy_priority_docket(days_ago, judge)
      veteran = create_veteran_for_cavc_legacy_priority

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_non_aod_video_vacols_case(veteran,
                                            correspondent,
                                            judge,
                                            days_ago)

      cavc_legacy_priority_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: cavc_legacy_priority_appeal)
      Timecop.return
      Timecop.travel(days_ago)
        remand = create(:cavc_remand, source_appeal: cavc_legacy_priority_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      Timecop.return
    end

    def create_veteran_for_cavc_legacy_priority
      @cavc_legacy_prior_file_number += 1
      @cavc_legacy_prior_participant_id += 1
      create_veteran(
        file_number: @cavc_legacy_prior_file_number,
        participant_id: @cavc_legacy_prior_participant_id
      )
    end

    # CAVC Hearings Creation Functions
    def create_cavc_hearing_non_priority_docket(days_ago, judge)
      Timecop.travel(days_ago + 1.day)
        cavc_hearing_non_priority_docket = create(
          :appeal,
          :hearing_docket,
          :held_hearing,
          :tied_to_judge,
          :dispatched,
          veteran: create_veteran_for_cavc_hearing_non_priority,
          receipt_date: days_ago,
          tied_judge: judge,
          associated_judge: judge,
          adding_user: User.first,
          associated_attorney: find_attorney("CAVCATNY")
        )
      Timecop.return
      Timecop.travel(days_ago)
        remand = create(:cavc_remand, source_appeal: cavc_hearing_non_priority_docket)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      Timecop.return
    end

    def create_veteran_for_cavc_hearing_non_priority
      @cavc_hearing_np_file_number += 1
      @cavc_hearing_np_participant_id += 1
      create_veteran(
        file_number: @cavc_hearing_np_file_number,
        participant_id: @cavc_hearing_np_participant_id
      )
    end

    def create_cavc_hearing_priority_docket(days_ago, judge)
      cavc_hearing_priority_docket = create(
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
      Timecop.travel(days_ago)
        remand = create(:cavc_remand, source_appeal: cavc_hearing_priority_docket)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
      Timecop.return
    end

    def create_veteran_for_cavc_hearing_priority
      @cavc_hearing_prior_file_number += 1
      @cavc_hearing_prior_participant_id += 1
      create_veteran(
        file_number: @cavc_hearing_prior_file_number,
        participant_id: @cavc_hearing_prior_participant_id
      )
    end

    # Legacy Creation Functions
    def create_aod_video_vacols_case(veteran, correspondent, judge, days_ago)
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
        bfd19: days_ago
      )
    end

    def create_non_aod_video_vacols_case(veteran, correspondent, judge, days_ago)
      create(
        :case,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: judge,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: days_ago
      )
    end

    def create_legacy_non_priority_docket(days_ago, judge)
      Timecop.travel(days_ago)
      veteran = create_veteran_for_legacy_non_priority

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_non_aod_video_vacols_case(veteran,
                                            correspondent,
                                            judge,
                                            days_ago)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)
      Timecop.return
    end

    def create_veteran_for_legacy_non_priority
      @legacy_np_file_number += 1
      @legacy_np_participant_id += 1
      create_veteran(
        file_number: @legacy_np_file_number,
        participant_id: @legacy_np_participant_id
      )
    end

    def create_legacy_priority_docket(days_ago, judge)
      Timecop.travel(days_ago)
      veteran = create_veteran_for_legacy_priority

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_aod_video_vacols_case(veteran,
                                            correspondent,
                                            judge,
                                            days_ago)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )

      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)
      Timecop.return
    end

    def create_veteran_for_legacy_priority
      @legacy_prior_file_number += 1
      @legacy_prior_participant_id += 1
      create_veteran(
        file_number: @legacy_prior_file_number,
        participant_id: @legacy_prior_participant_id
      )
    end
  end
end
