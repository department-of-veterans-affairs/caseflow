FactoryBot.define do
  factory :veteran do
    transient do
      bgs_veteran_record do
        {
          first_name: "Bob",
          last_name: "Smith"
        }
      end
    end

    sequence(:file_number, 10_000)

    after(:build) do |veteran, _evaluator|
      Fakes::BGSService.veteran_records ||= {}
      Fakes::BGSService.veteran_records[veteran.file_number] = bgs_veteran_record
    end
  end
end
