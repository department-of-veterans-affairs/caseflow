FactoryBot.define do
  factory :task do
    assigned_at { rand(30..35).days.ago }
    assigned_by { create(:user) }
    assigned_to { create(:user) }
    appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    action { nil }
    type { Task.name }

    trait :in_progress do
      status Constants.TASK_STATUSES.in_progress
      started_at { rand(1..10).days.ago }
    end

    trait :on_hold do
      status Constants.TASK_STATUSES.on_hold
      started_at { rand(20..30).days.ago }
      placed_on_hold_at { rand(1..10).days.ago }
      on_hold_duration [30, 60, 90].sample
    end

    trait :completed do
      status Constants.TASK_STATUSES.completed
      started_at { rand(20..30).days.ago }
      placed_on_hold_at { rand(1..10).days.ago }
      on_hold_duration [30, 60, 90].sample
      completed_at Time.zone.now
    end

    factory :root_task do
      type RootTask.name
      appeal { create(:appeal) }
      assigned_by { nil }
      assigned_to { Bva.singleton }
    end

    factory :generic_task do
      type GenericTask.name
      appeal { create(:appeal) }
    end

    factory :colocated_task do
      type ColocatedTask.name
      action { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.sample }
      instructions ["poa is missing"]
    end

    factory :ama_colocated_task do
      type ColocatedTask.name
      action { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.sample }
      instructions ["poa is missing"]
      appeal { create(:appeal) }
    end

    factory :ama_judge_task, class: JudgeAssignTask do
      type JudgeAssignTask.name
      appeal { create(:appeal) }
    end

    factory :ama_judge_review_task, class: JudgeReviewTask do
      type JudgeReviewTask.name
      appeal { create(:appeal) }
    end

    factory :ama_attorney_task do
      type AttorneyTask.name
      appeal { create(:appeal) }
      parent { create(:ama_judge_task) }
    end

    factory :ama_vso_task do
      type GenericTask.name
      appeal { create(:appeal) }
      parent { create(:root_task) }
    end

    factory :qr_task, class: QualityReviewTask do
      type QualityReviewTask.name
      appeal { create(:appeal) }
      parent { create(:root_task) }
      assigned_by { nil }
      assigned_to { QualityReview.singleton }
    end

    factory :bva_dispatch_task do
      type BvaDispatchTask.name
      appeal { create(:appeal) }
      assigned_by nil
    end

    factory :schedule_hearing_task do
      type ScheduleHearingTask.name
      appeal { create(:appeal) }
      assigned_by nil
    end

    factory :quality_review_task do
      type QualityReviewTask.name
      appeal { create(:appeal) }
      assigned_by nil
    end

    factory :informal_hearing_presentation_task do
      type InformalHearingPresentationTask.name
      appeal { create(:appeal) }
      assigned_by nil
    end

    factory :higher_level_review_task do
      type DecisionReviewTask.name
      appeal { create(:higher_level_review) }
      assigned_by nil
    end
  end
end
