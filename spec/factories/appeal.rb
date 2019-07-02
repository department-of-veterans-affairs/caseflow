# frozen_string_literal: true

FactoryBot.define do
  factory :appeal do
    transient do
      number_of_claimants { nil }
    end

    transient do
      active_task_assigned_at { Time.zone.now }
    end

    sequence(:veteran_file_number, 500_000_000)
    docket_type { Constants.AMA_DOCKETS.evidence_submission }

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) || create(:veteran, file_number: veteran_file_number)
      end
    end

    transient do
      associated_judge do
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101)
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)

        judge
      end
    end

    uuid do
      SecureRandom.uuid
    end

    established_at { Time.zone.now }
    receipt_date { Time.zone.yesterday }

    after(:create) do |appeal, _evaluator|
      appeal.request_issues.each do |issue|
        issue.decision_review = appeal
        issue.save
      end
    end

    trait :hearing_docket do
      docket_type { Constants.AMA_DOCKETS.hearing }
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

    trait :with_post_intake_tasks do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
      end
    end

    trait :ready_for_distribution do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        distribution_tasks = appeal.tasks.select { |task| task.is_a?(DistributionTask) }
        distribution_tasks.each(&:ready_for_distribution!)
      end
    end

    # Currently only creates realistic task trees for direct_review docket
    # Hearing and Evidence dockets have open branches
    trait :assigned_to_judge do

      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        distribution_tasks = appeal.tasks.select { |task| task.is_a?(DistributionTask) }
        distribution_tasks.each(&:ready_for_distribution!)

        JudgeAssignTask.create!(appeal: appeal,
                                parent: appeal.root_task,
                                appeal_type: Appeal.name,
                                assigned_at: _evaluator.active_task_assigned_at,
                                assigned_to: _evaluator.associated_judge,
                                action: COPY::JUDGE_ASSIGN_TASK_LABEL)
        appeal.tasks.where(type: DistributionTask.name).update(status: :completed)

      end
    end

    trait :outcoded do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    transient do
      documents { [] }
    end

    after(:build) do |appeal, evaluator|
      if evaluator.veteran
        appeal.veteran_file_number = evaluator.veteran.file_number
      end

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
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
  end
end
