FactoryBot.define do
  factory :appeal do
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

    uuid do
      SecureRandom.uuid
    end
  end
end
