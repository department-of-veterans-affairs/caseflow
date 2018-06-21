FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case nil
    end

    vacols_id { vacols_case.bfkey }
    vbms_id { vacols_case.bfcorlid }

    after(:create) do |legacy_appeal, _evaluator|
      if !Veteran.find_by(file_number: legacy_appeal.veteran_file_number)
        create(:veteran, file_number: legacy_appeal.veteran_file_number)
      end
    end
  end
end
