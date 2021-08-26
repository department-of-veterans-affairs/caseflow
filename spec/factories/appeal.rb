# frozen_string_literal: true

FactoryBot.define do
  factory :appeal do
    docket_type { Constants.AMA_DOCKETS.evidence_submission }
    established_at { Time.zone.now }
    receipt_date { Time.zone.yesterday }
    filed_by_va_gov { false }
    sequence(:veteran_file_number, 500_000_000)
    uuid { SecureRandom.uuid }

    after(:build) do |appeal, evaluator|
      if evaluator.veteran
        appeal.veteran_file_number = evaluator.veteran.file_number
      end

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
    end

    # Appeal's after_save interferes with explicit updated_at values
    after(:create) do |appeal, evaluator|
      appeal.touch(time: evaluator.updated_at) if evaluator.try(:updated_at)
    end

    after(:create) do |appeal, _evaluator|
      appeal.request_issues.each do |issue|
        issue.decision_review = appeal
        issue.save
      end
    end

    after(:create) do |appeal, evaluator|
      if !appeal.claimants.empty?
        appeal.claimants.each do |claimant|
          claimant.decision_review = appeal
          claimant.save
        end
      elsif evaluator.number_of_claimants
        claimant_class_name = appeal.veteran_is_not_claimant ? "DependentClaimant" : "VeteranClaimant"
        create_list(
          :claimant,
          evaluator.number_of_claimants,
          decision_review: appeal,
          type: claimant_class_name
        )
      elsif evaluator.has_unrecognized_appellant
        create(
          :claimant,
          :with_unrecognized_appellant_detail,
          participant_id: appeal.veteran.participant_id,
          decision_review: appeal,
          type: "OtherClaimant"
        )
      elsif !Claimant.exists?(participant_id: appeal.veteran.participant_id, decision_review: appeal)
        create(
          :claimant,
          participant_id: appeal.veteran.participant_id,
          decision_review: appeal,
          payee_code: "00",
          type: "VeteranClaimant"
        )
      end
    end

    transient do
      active_task_assigned_at { Time.zone.now }
    end

    transient do
      associated_attorney do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101) do |user|
          user.full_name = "BVAAABSHIRE"
        end
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        attorney = User.find_or_create_by(css_id: "BVAEERDMAN", station_id: 101) do |user|
          user.full_name = "BVAEERDMAN"
        end
        judge_team.add_user(attorney)
        create(:staff, :attorney_role, sdomainid: attorney.css_id)

        attorney
      end
    end

    transient do
      associated_judge do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101) do |user|
          user.full_name = "BVAAABSHIRE"
        end
        JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        create(:staff, :judge_role, sdomainid: judge.css_id)

        judge
      end
    end

    transient do
      documents { [] }
    end

    transient do
      number_of_claimants { nil }
      issue_count { nil }
    end

    transient do
      has_unrecognized_appellant { false }
    end

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) || create(:veteran, file_number: veteran_file_number)
      end
    end

    transient do
      disposition { "allowed" }
    end

    trait :type_cavc_remand do
      stream_type { Constants.AMA_STREAM_TYPES.court_remand }
      transient do
        remand_subtype { Constants.CAVC_REMAND_SUBTYPES.jmpr }
      end
      initialize_with do
        cavc_remand = create(:cavc_remand,
                             remand_subtype: remand_subtype,
                             veteran: veteran,
                             # pass docket type so that the created source appeal is the same docket type
                             docket_type: attributes[:docket_type])
        # cavc_remand creation triggers creation of a remand_appeal having appropriate tasks depending on remand_subtype
        cavc_remand.remand_appeal
      end
    end

    trait :hearing_docket do
      docket_type { Constants.AMA_DOCKETS.hearing }
    end

    trait :evidence_submission_docket do
      docket_type { Constants.AMA_DOCKETS.evidence_submission }
    end

    trait :direct_review_docket do
      docket_type { Constants.AMA_DOCKETS.direct_review }
    end

    trait :held_hearing do
      transient do
        adding_user { nil }
      end

      after(:create) do |appeal, evaluator|
        create(:hearing, judge: nil, disposition: "held", appeal: appeal, adding_user: evaluator.adding_user)
      end
    end

    trait :tied_to_judge do
      transient do
        tied_judge { nil }
      end

      after(:create) do |appeal, evaluator|
        hearing_day = create(
          :hearing_day,
          scheduled_for: 1.day.ago,
          created_by: evaluator.tied_judge,
          updated_by: evaluator.tied_judge
        )
        Hearing.find_by(disposition: Constants.HEARING_DISPOSITION_TYPES.held, appeal: appeal).update!(
          judge: evaluator.tied_judge,
          hearing_day: hearing_day
        )
      end
    end

    trait :outcoded do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    trait :advanced_on_docket_due_to_age do
      after(:create) do |appeal, _evaluator|
        appeal.claimants = [create(:claimant, :advanced_on_docket_due_to_age, decision_review: appeal)]
      end
    end

    trait :active do
      before(:create) do |appeal, _evaluator|
        RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
      end
    end

    trait :advanced_on_docket_due_to_motion do
      # the appeal has to be established before the motion is created to apply to it.
      established_at { Time.zone.now - 1 }
      after(:create) do |appeal|
        # Create an appeal with two claimants, one with a denied AOD motion
        # and one with a granted motion. The appeal should still be counted as AOD. Appeals only support one claimant,
        # so set the aod claimant as the last claimant on the appeal (and create it last)
        another_claimant = create(:claimant, decision_review: appeal)
        create(:advance_on_docket_motion, person: another_claimant.person, granted: false, appeal: appeal)

        claimant = create(:claimant, decision_review: appeal)
        create(:advance_on_docket_motion, person: claimant.person, granted: true, appeal: appeal)

        appeal.claimants = [another_claimant, claimant]
      end
    end

    trait :cancelled do
      after(:create) do |appeal, _evaluator|
        # make sure a request issue exists, then mark all removed
        create(:request_issue, decision_review: appeal)
        appeal.reload.request_issues.each(&:remove!)

        # Cancel the task tree
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        root_task.cancel_task_and_child_subtasks
      end
    end

    trait :denied_advance_on_docket do
      established_at { Time.zone.yesterday }
      after(:create) do |appeal|
        appeal.claimants { [create(:claimant, decision_review: appeal)] }
        create(:advance_on_docket_motion, person: appeal.claimants.last.person, granted: false, appeal: appeal)
      end
    end

    trait :inapplicable_aod_motion do
      established_at { Time.zone.tomorrow }
      after(:create) do |appeal|
        appeal.claimants { [create(:claimant, decision_review: appeal)] }
        create(:advance_on_docket_motion, person: appeal.claimants.last.person, granted: true, appeal: appeal)
        create(:advance_on_docket_motion, person: appeal.claimants.last.person, granted: false, appeal: appeal)
      end
    end

    trait :with_schedule_hearing_tasks do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
      end
    end

    trait :with_evidence_submission_window_task do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        EvidenceSubmissionWindowTask.create!(appeal: appeal, parent: root_task)
      end
    end

    trait :with_deceased_veteran do
      after(:create) do |appeal, _evaluator|
        appeal.veteran.update!(date_of_death: 1.month.ago)
      end
    end

    trait :with_ihp_task do
      after(:create) do |appeal, _evaluator|
        org = Organization.find_by(type: "Vso")
        FactoryBot.create(
          :informal_hearing_presentation_task,
          appeal: appeal,
          assigned_to: org
        )
      end
    end

    ## Appeal with a realistic task tree
    ## Appeal has finished intake
    trait :with_post_intake_tasks do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is ready for distribution by the ACD
    trait :ready_for_distribution do
      with_post_intake_tasks
      completed_distribution_task
    end

    trait :cavc_ready_for_distribution do
      completed_distribution_task
    end

    trait :completed_distribution_task do
      after(:create) do |appeal, _evaluator|
        distribution_tasks = appeal.tasks.select { |task| task.is_a?(DistributionTask) }
        (distribution_tasks.flat_map(&:descendants) - distribution_tasks).each(&:completed!)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is waiting for CAVC Response
    trait :cavc_response_window_open do
      type_cavc_remand
      after(:create) do |appeal, _evaluator|
        send_letter_task = appeal.tasks.find { |task| task.is_a?(SendCavcRemandProcessedLetterTask) }
        send_letter_task.update_from_params({ status: "completed" }, CavcLitigationSupport.singleton.admins.first)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal has finished waiting for a CAVC Response
    trait :cavc_response_window_complete do
      cavc_response_window_open
      after(:create) do |appeal, _evaluator|
        timed_hold_task = appeal.reload.tasks.find { |task| task.is_a?(TimedHoldTask) }
        timed_hold_task.completed!
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal would be ready for distribution by the ACD except there is a blocking mail task
    trait :mail_blocking_distribution do
      ready_for_distribution
      after(:create) do |appeal, _evaluator|
        distribution_task = appeal.tasks.active.detect { |task| task.is_a?(DistributionTask) }
        create(
          :extension_request_mail_task,
          appeal: appeal,
          parent: distribution_task
        )
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a Judge for a decision
    ## Strongly suggest you provide a judge.
    trait :assigned_to_judge do
      ready_for_distribution
      after(:create) do |appeal, evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        JudgeAssignTask.create!(appeal: appeal,
                                parent: root_task,
                                assigned_at: evaluator.active_task_assigned_at,
                                assigned_to: evaluator.associated_judge)
        appeal.tasks.of_type(:DistributionTask).update(status: :completed)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to an Attorney for decision drafting
    ## Strongly suggest you provide a judge and attorney.
    trait :at_attorney_drafting do
      assigned_to_judge
      after(:create) do |appeal, evaluator|
        judge_assign_task = appeal.tasks.of_type(:JudgeAssignTask).first
        AttorneyTaskCreator.new(
          judge_assign_task,
          appeal: judge_assign_task.appeal,
          assigned_to: evaluator.associated_attorney,
          assigned_by: judge_assign_task.assigned_to
        ).call
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a judge at decision review
    ## Strongly suggest you provide a judge and attorney.
    trait :at_judge_review do
      at_attorney_drafting
      after(:create) do |appeal, _evaluator|
        # MISSING: AttorneyCaseReview
        appeal.tasks.of_type(:AttorneyTask).first.completed!
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a judge at decision review
    ## Strongly suggest you provide a judge and attorney.
    trait :at_bva_dispatch do
      at_judge_review
      after(:create) do |appeal|
        # MISSING: JudgeCaseReview
        # BvaDispatchTask.create_from_root_task will autoassign, so need to have a non-empty BvaDispatch org
        BvaDispatch.singleton.add_user(create(:user)) if BvaDispatch.singleton.users.empty?
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        BvaDispatchTask.create_from_root_task(root_task)
        appeal.tasks.of_type(:JudgeDecisionReviewTask).first.completed!
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a judge at decision review
    ## Strongly suggest you provide a judge and attorney.
    trait :dispatched do
      at_bva_dispatch
      after(:create) do |appeal|
        create(:decision_document,
               :processed,
               appeal: appeal,
               citation_number: "A882#{(appeal.id % 100_000).to_s.rjust(5, '0')}")
        dispatch = AmaAppealDispatch.new(appeal: appeal, params: { bar: "foo" }, user: User.first)
        appeal.tasks.of_type(:BvaDispatchTask).assigned_to_any_user.first.completed!
        appeal.root_task.completed!
        dispatch.send(:close_request_issues_as_decided!)
        dispatch.send(:store_poa_participant_id)
      end
    end

    # An appeal which was dispatched, but has then had other open tasks added.
    # Note that the -ed suffix in 'dispatched' does not carry over to 'post_dispatch', which is how
    # it is referred to elsewhere in the code.
    trait :post_dispatch do
      dispatched
      after(:create) do |appeal|
        create(:congressional_interest_mail_task, parent: appeal.root_task)
      end
    end

    trait :with_straight_vacate_stream do
      dispatched
      after(:create) do |appeal, evaluator|
        mail_task = create(
          :vacate_motion_mail_task,
          appeal: appeal,
          parent: appeal.root_task,
          assigned_to: evaluator.associated_judge
        )
        addr_task = create(
          :judge_address_motion_to_vacate_task,
          appeal: appeal,
          parent: mail_task,
          assigned_to: evaluator.associated_judge
        )
        params = {
          disposition: "granted",
          vacate_type: "straight_vacate",
          instructions: "some instructions",
          assigned_to_id: evaluator.associated_attorney.id
        }
        PostDecisionMotionUpdater.new(addr_task, params).process
        mail_task.completed!
      end
    end

    trait :with_request_issues do
      description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
      notes = "Pain disorder with 100\% evaluation per examination"

      after(:create) do |appeal, evaluator|
        FactoryBot.create_list(
          :request_issue,
          evaluator.issue_count || Random.rand(1..10),
          :rating,
          decision_review: appeal,
          contested_issue_description: description,
          notes: notes
        )
      end
    end

    trait :with_decision_issue do
      description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
      notes = "Pain disorder with 100\% evaluation per examination"
      after(:create) do |appeal, evaluator|
        request_issue = create(:request_issue,
                               :rating,
                               :with_rating_decision_issue,
                               decision_review: appeal,
                               veteran_participant_id: appeal.veteran.participant_id,
                               contested_issue_description: description,
                               notes: notes)
        decision_issue = create(:decision_issue,
                                :rating,
                                decision_review: appeal,
                                disposition: evaluator.disposition,
                                description: "Issue description",
                                decision_text: "Decision text")
        request_issue.decision_issues << decision_issue
      end
    end

    trait :decision_issue_with_future_date do
      description = "Service connection for pain disorder"
      notes = "Pain disorder notes"
      after(:create) do |appeal, evaluator|
        request_issue = create(:request_issue,
                               :rating,
                               decision_review: appeal,
                               veteran_participant_id: appeal.veteran.participant_id,
                               contested_issue_description: description,
                               notes: notes)
        request_issue.create_decision_issue_from_params(disposition: evaluator.disposition,
                                                        description: description,
                                                        decision_date: 2.months.from_now)
      end
    end

    trait :decision_issue_with_no_decision_date do
      description = "Service connection for pain disorder"
      notes = "Pain disorder notes"
      after(:create) do |appeal, evaluator|
        request_issue = create(:request_issue,
                               :rating,
                               decision_review: appeal,
                               veteran_participant_id: appeal.veteran.participant_id,
                               contested_issue_description: description,
                               notes: notes)
        request_issue.create_decision_issue_from_params(disposition: evaluator.disposition,
                                                        description: description,
                                                        decision_date: nil)
      end
    end
  end

  trait :decision_issue_with_no_end_product_last_action_date do
    description = "Service connection for pain disorder"
    notes = "Pain disorder notes"
    after(:create) do |appeal, evaluator|
      request_issue = create(:request_issue,
                             :rating,
                             decision_review: appeal,
                             veteran_participant_id: appeal.veteran.participant_id,
                             contested_issue_description: description,
                             notes: notes)
      decision_issue = create(:decision_issue,
                              :rating,
                              decision_review: appeal,
                              disposition: evaluator.disposition,
                              description: "Issue description",
                              decision_text: "Decision text",
                              caseflow_decision_date: nil,
                              rating_promulgation_date: nil)
      request_issue.decision_issues << decision_issue
    end
  end
end
