FactoryBot.define do
  factory :appeal do
    trait :appellant_not_veteran do
      after(:create) do |appeal|
        appeal.claimants = [create(:claimant)]
      end
    end

    sequence(:veteran_file_number, 100_000_000)

    transient do
      veteran nil
    end

    uuid do
      SecureRandom.uuid
    end

    established_at { Time.zone.now }

    after(:create) do |appeal, evaluator|
      appeal.request_issues.each do |issue|
        issue.review_request = appeal
        issue.save
      end
      appeal.update(veteran_file_number: veteran.file_number) if evaluator.veteran
    end

    transient do
      documents []
    end

    after(:build) do |appeal, evaluator|
      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.veteran_file_number] = evaluator.documents
    end
  end
end
