FactoryBot.define do
  factory :higher_level_review do
    trait :appellant_not_veteran do
      after(:create) do |appeal|
        appeal.claimants = [create(:claimant)]
      end
    end

    transient do
      veteran nil
    end

    veteran_file_number do
      if veteran
        veteran.file_number
      end
    end

    established_at { Time.zone.now }
  end
end
