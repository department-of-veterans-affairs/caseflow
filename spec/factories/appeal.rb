FactoryBot.define do
  factory :appeal do
    transient do
      veteran nil
    end

    veteran_file_number do
      if veteran
        veteran.file_number
      end
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
  end
end
