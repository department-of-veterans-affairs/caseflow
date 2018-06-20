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

    sequence(:file_number, 100_000_000)

    after(:build) do |veteran, evaluator|
      Fakes::BGSService.veteran_records ||= {}
      Fakes::BGSService.veteran_records[veteran.file_number] =
        evaluator.bgs_veteran_record.merge(file_number: veteran.file_number)
    end
  end
end
