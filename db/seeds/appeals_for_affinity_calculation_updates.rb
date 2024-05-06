# frozen_string_literal: true

module Seeds
  class AppealsForAffinityCalculationUpdates < Base
    DISTRIBUTED_NONPRIORITY_RECEIPT_DATE = 1.year.ago
    DISTRIBUTED_PRIORITY_RECEIPT_DATE = 1.week.ago

    def initialize
      initial_id_values
    end

    def seed!
      RequestStore[:current_user] = User.system_user

      create_distributed_appeals_for_job_receipt_dates

      Timecop.travel(90.days.ago) do
        create_ready_appeals_with_no_affinity_record
        create_ready_appeals_with_affinity_no_start_date
        # These are appeals with an expired affinity
        create_ready_appeals_with_affinity
        create_non_ready_appeals_with_affinity
      end
      # These are appeals with an unexpired affinity
      create_ready_appeals_with_affinity
      create_ready_appeals_no_affinity_to_be_created
    end

    private

    def initial_id_values
      @file_number ||= 950_000_000
      @participant_id ||= 950_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def create_distributed_appeals_for_job_receipt_dates
      Timecop.travel(4.days.ago) do
        distribution = create(:distribution, :completed, judge: distributed_judge)

        direct_appeal = create(:appeal, :type_cavc_remand, :direct_review_docket, :assigned_to_judge,
                               associated_judge: distributed_judge, receipt_date: DISTRIBUTED_PRIORITY_RECEIPT_DATE,
                               veteran: create_veteran)
        create(:distributed_case, appeal: direct_appeal, distribution: distribution)

        evidence_appeal = create(:appeal, :type_cavc_remand, :evidence_submission_docket, :assigned_to_judge,
                                 associated_judge: distributed_judge, receipt_date: DISTRIBUTED_PRIORITY_RECEIPT_DATE,
                                 veteran: create_veteran)
        create(:distributed_case, appeal: evidence_appeal, distribution: distribution)

        priority_hearing_appeal =
          create(:appeal, :advanced_on_docket_due_to_age, :hearing_docket, :assigned_to_judge,
                 associated_judge: distributed_judge, receipt_date: DISTRIBUTED_PRIORITY_RECEIPT_DATE,
                 veteran: create_veteran)
        create(:hearing, :held, judge: distributed_judge, appeal: priority_hearing_appeal)
        create(:distributed_case, appeal: priority_hearing_appeal, distribution: distribution)

        nonpriority_hearing_appeal =
          create(:appeal, :hearing_docket, :assigned_to_judge,
                 associated_judge: distributed_judge, receipt_date: DISTRIBUTED_NONPRIORITY_RECEIPT_DATE,
                 veteran: create_veteran)
        create(:hearing, :held, judge: distributed_judge, appeal: nonpriority_hearing_appeal)
        create(:distributed_case, appeal: nonpriority_hearing_appeal, distribution: distribution)
      end
    end

    def create_ready_appeals_with_no_affinity_record
      2.times do
        create(:appeal, :direct_review_docket, :type_cavc_remand, :ready_for_distribution,
               veteran: create_veteran(first_name: "Vet", last_name: "NoAffinityRecord"))
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :ready_for_distribution,
               veteran: create_veteran(first_name: "Vet", last_name: "NoAffinityRecord"))
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :held_hearing_and_ready_to_distribute,
               veteran: create_veteran(first_name: "Vet", last_name: "NoAffinityRecord"))
        create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute,
               veteran: create_veteran(first_name: "Vet", last_name: "NoAffinityRecord"))
      end
    end

    def create_ready_appeals_with_affinity_no_start_date
      2.times do
        create(:appeal, :direct_review_docket, :type_cavc_remand, :ready_for_distribution,
               :with_appeal_affinity_no_start_date,
               veteran: create_veteran(first_name: "VetWithAffinity", last_name: "NoStartDate"))
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :ready_for_distribution,
               :with_appeal_affinity_no_start_date,
               veteran: create_veteran(first_name: "VetWithAffinity", last_name: "NoStartDate"))
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age,
               :held_hearing_and_ready_to_distribute, :with_appeal_affinity_no_start_date,
               veteran: create_veteran(first_name: "VetWithAffinity", last_name: "NoStartDate"))
        create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute,
               :with_appeal_affinity_no_start_date,
               veteran: create_veteran(first_name: "VetWithAffinity", last_name: "NoStartDate"))
      end
    end

    def create_ready_appeals_with_affinity
      2.times do
        create(:appeal, :direct_review_docket, :type_cavc_remand, :ready_for_distribution,
               :with_appeal_affinity, veteran: create_veteran(first_name: "VetWithAffinity", last_name: "StartDate"))
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :ready_for_distribution,
               :with_appeal_affinity, veteran: create_veteran(first_name: "VetWithAffinity", last_name: "StartDate"))
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :held_hearing_and_ready_to_distribute,
               :with_appeal_affinity, veteran: create_veteran(first_name: "VetWithAffinity", last_name: "StartDate"))
        create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute,
               :with_appeal_affinity, veteran: create_veteran(first_name: "VetWithAffinity", last_name: "StartDate"))
      end
    end

    def create_non_ready_appeals_with_affinity
      2.times do
        create(:appeal, :direct_review_docket, :type_cavc_remand, :with_appeal_affinity,
               veteran: create_veteran(first_name: "VetNotReady", last_name: "WithAffinity"))
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :with_appeal_affinity,
               veteran: create_veteran(first_name: "VetNotReady", last_name: "WithAffinity"))
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :with_appeal_affinity,
               veteran: create_veteran(first_name: "VetNotReady", last_name: "WithAffinity"))
        create(:appeal, :hearing_docket, :with_appeal_affinity,
               veteran: create_veteran(first_name: "VetNotReady", last_name: "WithAffinity"))
      end
    end

    # The receipt date on these is the time of running the seed, so they shouldn't be selected when
    # running the new job with the distribuion ID from the distributed cases created here
    def create_ready_appeals_no_affinity_to_be_created
      5.times do
        create(:appeal, :direct_review_docket, :type_cavc_remand, :ready_for_distribution,
               veteran: create_veteran(first_name: "VetReady", last_name: "ShouldntGetAffinity"))
        create(:appeal, :evidence_submission_docket, :type_cavc_remand, :ready_for_distribution,
               veteran: create_veteran(first_name: "VetReady", last_name: "ShouldntGetAffinity"))
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :held_hearing_and_ready_to_distribute,
               veteran: create_veteran(first_name: "VetReady", last_name: "ShouldntGetAffinity"))
        create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute,
               veteran: create_veteran(first_name: "VetReady", last_name: "ShouldntGetAffinity"))
      end
    end

    def distributed_judge
      judge = User.find_by(css_id: "AFFCALCJUDGE") ||
                create(:user, :judge, :with_vacols_judge_record, css_id: "AFFCALCJUDGE",
                       full_name: "Joe AffinityCalc Judge")
      create_and_add_attorney_to_team(judge) if JudgeTeam.for_judge(judge).attorneys.empty?
      judge
    end

    # This will make this attorney's requested distributions only recieve 3 appeals (w/ default lever values)
    def create_and_add_attorney_to_team(judge)
      attorney = User.find_by(css_id: "AFFCALCATTY") ||
        create(:user, :with_vacols_attorney_record, css_id: "AFFCALCATTY", full_name: "Jane AffinityCalc Attorney")
      JudgeTeam.for_judge(judge).add_user(attorney)
    end
  end
end
