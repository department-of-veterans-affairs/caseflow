# frozen_string_literal: true

FactoryBot.define do
  factory :appeal do
    docket_type { Constants.AMA_DOCKETS.evidence_submission }
    established_at { Time.zone.now }
    receipt_date { Time.zone.yesterday }
    sequence(:veteran_file_number, 500_000_000)
    uuid { SecureRandom.uuid }

    after(:build) do |appeal, evaluator|
      if evaluator.veteran
        appeal.veteran_file_number = evaluator.veteran.file_number
      end

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
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
        appeal.claimants = create_list(:claimant, evaluator.number_of_claimants, decision_review: appeal)
      else
        appeal.claimants = [create(
          :claimant,
          participant_id: appeal.veteran.participant_id,
          decision_review: appeal,
          payee_code: "00"
        )]
      end
    end

    transient do
      active_task_assigned_at { Time.zone.now }
    end

    transient do
      associated_attorney do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101)
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        attorney = User.find_or_create_by(css_id: "BVAEERDMAN", station_id: 101)
        judge_team.add_user(attorney)

        attorney
      end
    end

    transient do
      associated_judge do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101)
        JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)

        judge
      end
    end

    transient do
      documents { [] }
    end

    transient do
      number_of_claimants { nil }
    end

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) || create(:veteran, file_number: veteran_file_number)
      end
    end

    trait :hearing_docket do
      docket_type { Constants.AMA_DOCKETS.hearing }
    end

    trait :outcoded do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    trait :advanced_on_docket_due_to_age do
      claimants { [create(:claimant, :advanced_on_docket_due_to_age)] }
    end

    trait :advanced_on_docket_due_to_motion do
      # the appeal has to be established before the motion is created to apply to it.
      established_at { Time.zone.now - 1 }
      claimants do
        # Create an appeal with two claimants, one with a denied AOD motion
        # and one with a granted motion. The appeal should still be counted as AOD.
        claimant = create(:claimant)
        another_claimant = create(:claimant)
        create(:advance_on_docket_motion, person: claimant.person, granted: true)
        create(:advance_on_docket_motion, person: another_claimant.person, granted: false)
        [claimant, another_claimant]
      end
    end

    trait :denied_advance_on_docket do
      established_at { Time.zone.yesterday }
      claimants do
        claimant = create(:claimant)

        create(:advance_on_docket_motion, person: claimant.person, granted: false)
        [claimant]
      end
    end

    trait :inapplicable_aod_motion do
      established_at { Time.zone.tomorrow }
      claimants do
        claimant = create(:claimant)
        create(:advance_on_docket_motion, person: claimant.person, granted: true)
        create(:advance_on_docket_motion, person: claimant.person, granted: false)
        [claimant]
      end
    end

    trait :with_schedule_hearing_tasks do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
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
    ## Leaves incorrectly open & incomplete Hearing / Evidence Window task branches
    ## for those dockets
    trait :ready_for_distribution do
      with_post_intake_tasks
      after(:create) do |appeal, _evaluator|
        distribution_tasks = appeal.tasks.select { |task| task.is_a?(DistributionTask) }
        distribution_tasks.each(&:ready_for_distribution!)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to a Judge for a decision
    ## Leaves incorrectly open & incomplete Hearing / Evidence Window task branches
    ## for those dockets. Strongly suggest you provide a judge.
    trait :assigned_to_judge do
      ready_for_distribution
      after(:create) do |appeal, evaluator|
        JudgeAssignTask.create!(appeal: appeal,
                                parent: appeal.root_task,
                                assigned_at: evaluator.active_task_assigned_at,
                                assigned_to: evaluator.associated_judge)
        appeal.tasks.where(type: DistributionTask.name).update(status: :completed)
      end
    end

    ## Appeal with a realistic task tree
    ## The appeal is assigned to an Attorney for decision drafting
    ## Leaves incorrectly open & incomplete Hearing / Evidence Window task branches
    ## for those dockets. Strongly suggest you provide a judge and attorney.
    trait :at_attorney_drafting do
      assigned_to_judge
      after(:create) do |appeal, evaluator|
        judge_assign_task = appeal.tasks.where(type: JudgeAssignTask.name).first
        AttorneyTaskCreator.new(
          judge_assign_task,
          appeal: judge_assign_task.appeal,
          assigned_to: evaluator.associated_attorney,
          assigned_by: judge_assign_task.assigned_to
        ).call
      end
    end

    trait :straight_vacated do
      stream_type { "Vacate" }

      after(:create) do |appeal, evaluator|
        task = JudgeAddressMotionToVacateTask.create!(
          appeal: appeal,
          parent: appeal.root_task,
          assigned_at: evaluator.active_task_assigned_at,
          assigned_to: evaluator.associated_judge)
        params = {
          disposition: "granted",
          vacate_type: "straight_vacate",
          instructions: "some instructions",
          assigned_to_id: task.assigned_to.id}
        PostDecisionMotionUpdater.new(task, params).process
      end
    end
  end
end
