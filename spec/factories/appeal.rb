FactoryBot.define do
  factory :appeal do
    trait :appellant_not_veteran do
      after(:create) do |appeal|
        appeal.claimants = [create(:claimant)]
      end
    end

    sequence(:veteran_file_number, 500_000_000)

    transient do
      veteran nil
    end

    uuid do
      SecureRandom.uuid
    end

    established_at { Time.zone.now }

    after(:create) do |appeal, _evaluator|
      appeal.request_issues.each do |issue|
        issue.review_request = appeal
        issue.save
      end
    end

    transient do
      documents []
    end

    after(:build) do |appeal, evaluator|
      if evaluator.veteran
        appeal.veteran_file_number = evaluator.veteran.file_number
        appeal.save
      end

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
    end
  end
end
