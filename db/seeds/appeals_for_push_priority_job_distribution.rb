# frozen_string_literal: true

# This seed file creates ready appeals for testing the function of the PushPriorityAppealsToJudgesJob

module Seeds
  class AppealsForPushPriorityJobDistribution < Base
    def seed!
      RequestStore[:current_user] = User.system_user

      # TODO: take the transaction block out after testing
      ApplicationRecord.multi_transaction do
        instantiate_judges
        create_direct_review_cases
        create_evidence_submission_cases
        create_hearing_cases
        create_legacy_cases
        create_aoj_legacy_cases
        create_previous_distribtions
      end

      IneligibleJudgesJob.perform_now
    end

    private

    # no appeals should be created as tied to or with affinity to these judges so they receive only genpop appeals
    # create them first so that they are distributed to first when the push job runs
    def judge_no_tied_affinity_cases_1
      @judge_no_tied_affinity_cases_1 ||= User.find_by(css_id: "GENPOPJUDGE1") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "GENPOPJUDGE1", full_name: "GenpopJudge NoAffinityTiedCasesOne")
    end

    def judge_no_tied_affinity_cases_2
      @judge_no_tied_affinity_cases_2 ||= User.find_by(css_id: "GENPOPJUDGE2") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "GENPOPJUDGE2", full_name: "GenpopJudge NoAffinityTiedCasesTwo")
    end

    # this judge's JudgeTeam should not receive any cases during the push priority job run
    def judge_no_push_cases
      @judge_no_push_cases ||= (
        user = User.find_by(css_id: "NOPUSHJUDGE1") ||
          create(:user, :judge, :with_vacols_judge_record,
                 css_id: "NOPUSHJUDGE1", full_name: "PushJudge NotAcceptingCases")

        JudgeTeam.for_judge(user).update!(accepts_priority_pushed_cases: false)
        user
      )
    end

    # this judge will have several prior distribution created to set their monthly appeals distributed count
    # too high to be included in the eligible judges after a priority target is calculated
    def judge_many_previous_distributions
      @judge_many_previous_distributions ||= User.find_by(css_id: "NOPUSHJUDGE2") ||
        create(:user, :judge, :with_vacols_judge_record,
               css_id: "NOPUSHJUDGE2", full_name: "PushJudge ManyPrevCases")
    end

    # this judge will have a single prior distribution created to set their monthly appeals distributed count
    # too high to be included in the eligible judges after a priority target is calculated
    def judge_one_large_previous_distribution
      @judge_one_large_previous_distributions ||= User.find_by(css_id: "NOPUSHJUDGE3") ||
        create(:user, :judge, :with_vacols_judge_record,
               css_id: "NOPUSHJUDGE3", full_name: "PushJudge OneLargePrevDist")
    end

    # a balanced number of appeals should be created which have an affinity to or are tied to these judges
    def judge_1
      @judge_1 ||= User.find_by(css_id: "PUSHJUDGE1") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "PUSHJUDGE1", full_name: "PushJudge One")
    end

    def judge_2
      @judge_2 ||=  User.find_by(css_id: "PUSHJUDGE2") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "PUSHJUDGE2", full_name: "PushJudge Two")
    end

    def judge_3
      @judge_3 ||=  User.find_by(css_id: "PUSHJUDGE3") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "PUSHJUDGE3", full_name: "PushJudge Three")
    end

    def judge_4
      @judge_4 ||=  User.find_by(css_id: "PUSHJUDGE4") ||
        create(:user, :judge, :with_vacols_judge_record, css_id: "PUSHJUDGE4", full_name: "PushJudge Four")
    end

    # many appeals should be created which are tied to this judge so that a single run of the job will distribute
    # enough appeals to them where they will receieve no genpop appeals during the job run
    def judge_many_tied_cases
      @judge_many_tied_cases ||= User.find_by(css_id: "PUSHJUDGE5") ||
        create(:user, :judge, :with_vacols_judge_record,
               css_id: "PUSHJUDGE5", full_name: "PushJudge ManyTiedCases")
    end

    def other_judge
      @other_judge ||= User.find_by(css_id: "OTHER_JUDGE") ||
      create(:user, :judge, :with_vacols_judge_record,
             css_id: "OTHER_JUDGE", full_name: "OtherJudge ForAffinityCases")
    end

    def attorney
      @attorney ||= User.find_by(css_id: "PUSH_ATTY") ||
        create(:user, :with_vacols_attorney_record,
               css_id: "PUSH_ATTY", full_name: "AttorneyDrafted LotsOfCases")
    end

    def excluded_judge
      @excluded_judge ||= User.find_by(css_id: "EXCL_JUDGE") ||
        create(:user, :judge_with_appeals_excluded_from_affinity, :with_vacols_judge_record,
                      css_id: "EXCL_JUDGE", full_name: "Affinity ExcludedJudge")
    end

    def ineligible_judge
      @ineligible_judge ||= User.find_by(css_id: "INEL_JUDGE") ||
        create(:user, :judge, :with_inactive_vacols_judge_record,
               css_id: "INEL_JUDGE", full_name: "Vacols IneligibleJudge")
    end

    def instantiate_judges
      judge_no_tied_affinity_cases_1
      judge_no_tied_affinity_cases_2
      judge_1
      judge_2
      judge_3
      judge_4
      judge_no_push_cases
      judge_many_previous_distributions
      judge_one_large_previous_distribution
      excluded_judge
      ineligible_judge
    end

    def tied_or_affinity_judges
      [judge_1, judge_2, judge_3, judge_4, judge_no_push_cases, excluded_judge, ineligible_judge]
    end

    def create_direct_review_cases
      create_direct_review_priority_not_genpop_cases
      create_direct_review_priority_genpop_cases
      create_direct_review_priority_not_ready_cases
      create_direct_review_nonpriority_ready_cases
    end

    def create_evidence_submission_cases
      create_evidence_submission_priority_not_genpop_cases
      create_evidence_submission_priority_genpop_cases
      create_evidence_submission_priority_not_ready_cases
      create_evidence_submission_nonpriority_ready_cases
    end

    def create_hearing_cases
      create_hearing_priority_not_genpop_cases
      create_hearing_priority_genpop_cases
      create_hearing_priority_not_ready_cases
      create_hearing_nonpriority_ready_cases
    end

    def create_legacy_cases
      create_legacy_priority_not_genpop_cases
      create_legacy_priority_genpop_cases
      create_legacy_priority_not_ready_cases
      create_legacy_nonpriority_ready_cases
    end

    def create_aoj_legacy_cases
      create_aoj_legacy_priority_not_genpop_cases
      create_aoj_legacy_priority_genpop_cases
      create_aoj_legacy_priority_not_ready_cases
      create_aoj_legacy_nonpriority_ready_cases
    end

    # these distributions will cause the associated judges to not recieve as many (or any) cases in the push job
    def create_previous_distribtions
      statistics = { batch_size: 10, info: "See related row in distribution_stats for additional stats" }
      4.times do |n|
        create(:distribution, :completed, :priority,
               judge: judge_many_previous_distributions, completed_at: n.weeks.ago, statistics: statistics)
      end

      statistics = { batch_size: 100, info: "See related row in distribution_stats for additional stats" }
      create(:distribution, :completed, :priority, :this_month,
             judge: judge_one_large_previous_distribution, statistics: statistics)
    end

    def create_direct_review_priority_not_genpop_cases
      tied_or_affinity_judges.each do |judge|
        create(:appeal, :direct_review_docket, :type_cavc_remand, :cavc_ready_for_distribution, judge: judge)
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :type_cavc_remand, :cavc_ready_for_distribution, judge: judge)
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_motion, :type_cavc_remand, :cavc_ready_for_distribution, judge: judge)
      end
    end

    def create_direct_review_priority_genpop_cases
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_motion, :ready_for_distribution)

      # appeals which had affinity but are outside the window and can be distributed to other judges
      tied_or_affinity_judges.each do |judge|
        create(:appeal, :direct_review_docket, :type_cavc_remand, :cavc_ready_for_distribution, :with_appeal_affinity, judge: judge, affinity_start_date: 3.months.ago)
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :type_cavc_remand, :cavc_ready_for_distribution, :with_appeal_affinity, judge: judge, affinity_start_date: 3.months.ago)
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_motion, :type_cavc_remand, :cavc_ready_for_distribution, :with_appeal_affinity, judge: judge, affinity_start_date: 3.months.ago)
      end
    end

    def create_direct_review_priority_not_ready_cases
      # CAVC remands which are tied to a judge but not ready to distribute
      tied_or_affinity_judges.each do |judge|
        create(:appeal, :direct_review_docket, :type_cavc_remand, :cavc_response_window_open, judge: judge)
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :type_cavc_remand, :cavc_response_window_open, judge: judge)
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_motion, :type_cavc_remand, :cavc_response_window_open, judge: judge)
      end

      # genpop appeals with a blocking mail task that are not ready to distribute
      appeal_1 = create(:appeal, :direct_review_docket,
                        :advanced_on_docket_due_to_age, :ready_for_distribution)
      dist_task_1 = DistributionTask.find_by(appeal_id: appeal_1.id, appeal_type: 'Appeal')
      create(:congressional_interest_mail_task, parent: dist_task_1)

      appeal_2 = create(:appeal, :direct_review_docket,
                        :advanced_on_docket_due_to_motion, :ready_for_distribution)
      dist_task_2 = DistributionTask.find_by(appeal_id: appeal_2.id, appeal_type: 'Appeal')
      create(:congressional_interest_mail_task, parent: dist_task_2)
    end

    def create_direct_review_nonpriority_ready_cases
      create(:appeal, :direct_review_docket, :ready_for_distribution)
    end

    def create_evidence_submission_priority_not_genpop_cases
      tied_or_affinity_judges.each do |judge|
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :cavc_ready_for_distribution, judge: judge)
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :type_cavc_remand, :cavc_ready_for_distribution, judge: judge)
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_motion, :type_cavc_remand, :cavc_ready_for_distribution, judge: judge)
      end
    end

    def create_evidence_submission_priority_genpop_cases
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_motion, :ready_for_distribution)

      # appeals which had affinity but are outside the window and can be distributed to other judges
      tied_or_affinity_judges.each do |judge|
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :cavc_ready_for_distribution, :with_appeal_affinity, judge: judge, affinity_start_date: 3.months.ago)
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :type_cavc_remand, :cavc_ready_for_distribution, :with_appeal_affinity, judge: judge, affinity_start_date: 3.months.ago)
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_motion, :type_cavc_remand, :cavc_ready_for_distribution, :with_appeal_affinity, judge: judge, affinity_start_date: 3.months.ago)
      end
    end

    def create_evidence_submission_priority_not_ready_cases
      # CAVC remands which are tied to a judge but not ready to distribute
      tied_or_affinity_judges.each do |judge|
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :cavc_response_window_open, judge: judge)
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :type_cavc_remand, :cavc_response_window_open, judge: judge)
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_motion, :type_cavc_remand, :cavc_response_window_open, judge: judge)
      end

      # genpop appeals with a blocking mail task that are not ready to distribute
      appeal_1 = create(:appeal, :evidence_submission_docket,
                        :advanced_on_docket_due_to_age, :ready_for_distribution)
      dist_task_1 = DistributionTask.find_by(appeal_id: appeal_1.id, appeal_type: 'Appeal')
      create(:congressional_interest_mail_task, parent: dist_task_1)

      appeal_2 = create(:appeal, :evidence_submission_docket,
                        :advanced_on_docket_due_to_motion, :ready_for_distribution)
      dist_task_2 = DistributionTask.find_by(appeal_id: appeal_2.id, appeal_type: 'Appeal')
      create(:congressional_interest_mail_task, parent: dist_task_2)
    end

    def create_evidence_submission_nonpriority_ready_cases
      create(:appeal, :evidence_submission_docket, :ready_for_distribution)
    end

    def create_hearing_priority_not_genpop_cases; end
    def create_hearing_priority_genpop_cases; end
    def create_hearing_priority_not_ready_cases; end
    def create_hearing_nonpriority_ready_cases; end

    def create_legacy_priority_not_genpop_cases
      tied_or_affinity_judges.each do |judge|
        # hearing held type original AOD tied
        create(:case, :type_original, :aod, :tied_to_judge, :ready_for_distribution, tied_judge: judge)
        # hearing before decision CAVC tied
        create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff)
        # hearing after decision CAVC tied
        c = create(:legacy_cavc_appeal, judge: other_judge.vacols_staff, attorney: attorney.vacols_staff)
        create(:case_hearing, :disposition_held, folder_nr: (c.bfkey.to_i + 1), hearing_date: Time.zone.today, user: judge)
        # hearing before decision CAVC AOD tied
        create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff, aod: true)
        # hearing after decision CAVC AOD tied
        c = create(:legacy_cavc_appeal, judge: other_judge.vacols_staff, attorney: attorney.vacols_staff, aod: true)
        create(:case_hearing, :disposition_held, folder_nr: (c.bfkey.to_i + 1), hearing_date: Time.zone.today, user: judge)
        # hearing before decision different deciding judge CAVC affinity in window
        c = create(:legacy_cavc_appeal, judge: other_judge.vacols_staff, attorney: attorney.vacols_staff, affinity_start_date: 3.days.ago)
        c.update!(bfmemid: judge.vacols_attorney_id)
        # hearing before decision different deciding judge CAVC AOD affinity in window
        c = create(:legacy_cavc_appeal, judge: other_judge.vacols_staff, attorney: attorney.vacols_staff, affinity_start_date: 3.days.ago, aod: true)
        c.update!(bfmemid: judge.vacols_attorney_id)
        # no hearings CAVC affinity in window
        create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff, tied_to: false, affinity_start_date: 3.days.ago)
        # no hearings CAVC AOD affinity in window
        create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff, tied_to: false, affinity_start_date: 3.days.ago, aod: true)
      end
    end

    def create_legacy_priority_genpop_cases
      # no hearing type original AOD
      create(:case, :type_original, :ready_for_distribution)

      tied_or_affinity_judges.each do |judge|
        # hearing before decision different deciding judge CAVC affinity out of window
        c = create(:legacy_cavc_appeal, judge: other_judge.vacols_staff, attorney: attorney.vacols_staff, affinity_start_date: 2.months.ago)
        c.update!(bfmemid: judge.vacols_attorney_id)
        # hearing before decision different deciding judge CAVC AOD affinity out of window
        c = create(:legacy_cavc_appeal, judge: other_judge.vacols_staff, attorney: attorney.vacols_staff, affinity_start_date: 2.months.ago, aod: true)
        c.update!(bfmemid: judge.vacols_attorney_id)
        # no hearings CAVC affinity out of window
        create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff, tied_to: false, affinity_start_date: 2.months.ago)
        # no hearings CAVC AOD affinity out of window
        create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff, tied_to: false, affinity_start_date: 2.months.ago, aod: true)
      end
    end

    def create_legacy_priority_not_ready_cases
      create(:case, :aod, :video_hearing_requested, :type_original)

      tied_or_affinity_judges.each do |judge|
        original = create(:legacy_cavc_appeal, judge: judge.vacols_staff, attorney: attorney.vacols_staff, appeal_affinity: false)
        VACOLS::Case.find_by(bfkey: original.bfkey.to_i + 1).update!(bfcurloc: '57')
      end
    end

    def create_legacy_nonpriority_ready_cases
      create(:case, :type_original, :ready_for_distribution)

      tied_or_affinity_judges.each do |judge|
        create(:case, :type_original, :tied_to_judge, :ready_for_distribution, tied_judge: judge)
      end
    end

    def create_aoj_legacy_priority_not_genpop_cases; end
    def create_aoj_legacy_priority_genpop_cases; end
    def create_aoj_legacy_priority_not_ready_cases; end
    def create_aoj_legacy_nonpriority_ready_cases; end
  end
end
