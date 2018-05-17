FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case nil
    end

    vacols_id { vacols_case.bfkey }
    vbms_id { vacols_case.bfcorlid }

    after(:build) do |legacy_appeal, evaluator|
      create(:case, bfkey: legacy_appeal.vacols_id, bfcorlid: legacy_appeal.vbms_id) if !evaluator.vacols_case
    end
  end
end