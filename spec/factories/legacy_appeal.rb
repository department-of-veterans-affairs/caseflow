FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case nil
      veteran_first_name nil
      veteran_last_name nil
    end

    vacols_id { vacols_case.bfkey }
    vbms_id { vacols_case.bfcorlid }

    trait :with_veteran do
      after(:create) do |legacy_appeal, evaluator|
        create(:veteran, file_number: legacy_appeal.veteran_file_number)

        if evaluator.vacols_case
          evaluator.vacols_case.correspondent.snamef = evaluator.veteran_first_name if evaluator.veteran_first_name
          evaluator.vacols_case.correspondent.snamel = evaluator.veteran_last_name if evaluator.veteran_last_name
          evaluator.vacols_case.correspondent.save
        end
      end
    end
  end
end
