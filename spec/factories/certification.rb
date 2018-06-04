FactoryBot.define do
  factory :certification do
    transient do
      vacols_case nil
    end

    vacols_id { vacols_case.bfkey }
  end
end
