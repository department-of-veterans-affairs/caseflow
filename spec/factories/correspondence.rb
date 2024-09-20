# frozen_string_literal: true

FactoryBot.define do
  factory :correspondence do
    uuid { SecureRandom.uuid }
    va_date_of_receipt { Time.zone.yesterday }
    notes { "" }
    nod { false }
    correspondence_type
    veteran

    trait :nod do
      nod { true }
    end

    trait :completed do
      after(:create) do |correspondence|
        correspondence.review_package_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    trait :unassigned do
      after(:create) do |correspondence|
        correspondence.review_package_task.update!(status: Constants.TASK_STATUSES.unassigned)
      end
    end

    trait :related_correspondence do
      after(:create) do |correspondence|
        related_correspondence = Correspondence.create!(
          veteran: correspondence.veteran,
          uuid: SecureRandom.uuid,
          notes: "Related correspondence"
        )
        CorrespondenceRelation.create!(
          correspondence_id: correspondence.id,
          related_correspondence_id: related_correspondence.id
        )
      end
    end

    trait :action_required do
      after(:create) do |correspondence|
        ReassignPackageTask.create!(
          appeal: correspondence,
          appeal_type: Correspondence.name,
          parent: correspondence.review_package_task,
          assigned_to: InboundOpsTeam.singleton
        )
      end
    end

    trait :pending do
      after(:create) do |correspondence|
        create(
          :correspondence_intake_task,
          appeal: correspondence,
          appeal_type: Correspondence.name,
          parent: correspondence.root_task
        )
        correspondence.open_intake_task.update!(status: Constants.TASK_STATUSES.completed)
        correspondence.review_package_task.update!(status: Constants.TASK_STATUSES.completed)
        CavcCorrespondenceCorrespondenceTask.create!(
          appeal: correspondence,
          assigned_to: CavcLitigationSupport.singleton,
          appeal_type: Correspondence.name,
          parent: correspondence.root_task
        )
      end
    end

    trait :with_single_doc do
      after(:create) do |correspondence|
        create(:correspondence_document, correspondence: correspondence)
      end
    end

    # doubles as 'assigned' correspondence status.
    trait :with_correspondence_intake_task do
      transient do
        assigned_to { InboundOpsTeam.singleton.users.first }
      end

      after(:create) do |correspondence, evaluator|
        create(
          :correspondence_intake_task,
          appeal: correspondence,
          assigned_to: evaluator.assigned_to,
          appeal_type: Correspondence.name,
          parent: correspondence.root_task
        )
        # close out the review package task
        correspondence.review_package_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end
  end

  factory :correspondence_document do
    uuid { SecureRandom.uuid }
    document_type { 1250 }
    pages { 30 }
    vbms_document_type_id { 1250 }
    association :correspondence
  end
end
