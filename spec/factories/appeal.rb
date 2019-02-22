FactoryBot.define do
  factory :appeal do
    transient do
      number_of_claimants nil
    end

    sequence(:veteran_file_number, 500_000_000)
    docket_type Constants.AMA_DOCKETS.evidence_submission

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) || create(:veteran, file_number: veteran_file_number)
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
      docket_type Constants.AMA_DOCKETS.hearing
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

    trait :with_tasks do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
      end
    end

    trait :outcoded do
      after(:create) do |appeal, _evaluator|
        appeal.create_tasks_on_intake_success!
        appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    transient do
      documents []
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
          claimant.review_request = appeal
          claimant.save
        end
      elsif evaluator.number_of_claimants
        appeal.claimants = create_list(:claimant, evaluator.number_of_claimants, review_request: appeal)
      else
        appeal.claimants = [create(
          :claimant,
          participant_id: appeal.veteran.participant_id,
          review_request: appeal,
          payee_code: "00"
        )]
      end
    end
  end
end
