FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case nil
    end

    vacols_id { vacols_case.bfkey }
    vbms_id { vacols_case.bfcorlid }
  end
end
