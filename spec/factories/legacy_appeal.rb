FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case nil
    end

    vacols_id { vacols_case.bfkey }
    vbms_id { vacols_case.bfcorlid }

    trait :with_veteran do
      after(:create) do |legacy_appeal, _evaluator|
        create(:veteran, file_number: legacy_appeal.veteran_file_number)
      end
    end
  end
end
