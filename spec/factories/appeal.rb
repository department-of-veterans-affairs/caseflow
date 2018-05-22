FactoryBot.define do
  factory :appeal do
    transient do
      veteran
    end

    veteran_file_number do
      if veteran
        veteran.veteran_file_number
      else
        "783740847"
      end
    end

    after(:build) do |appeal, evaluator|
      Fakes::BGS
  end
end
