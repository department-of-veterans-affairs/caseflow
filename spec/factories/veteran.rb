# frozen_string_literal: true

FactoryBot.define do
  factory :veteran do
    first_name { "Bob" }
    last_name { "Smith#{Faker::Name.last_name.downcase}" }
    name_suffix { (bob_smith_count == 1) ? "II" : bob_smith_count.to_s }
    ssn { Generators::Random.unique_ssn }
    email_address { "#{first_name}.#{last_name}@test.com" }
    date_of_death { nil }

    transient do
      sequence(:bob_smith_count)
      sex { Faker::Gender.short_binary_type.upcase }
      bgs_veteran_record do
        {
          file_number: file_number,
          ssn: ssn,
          first_name: first_name,
          last_name: last_name,
          email_address: email_address,
          date_of_birth: "01/10/1935",
          date_of_death: date_of_death,
          name_suffix: name_suffix,
          sex: sex,
          address_line1: "1234 Main Street",
          country: "USA",
          zip_code: "12345",
          state: "FL",
          city: "Orlando",
          # both for compatibility
          ptcpnt_id: participant_id.to_s,
          participant_id: participant_id.to_s
        }
      end
    end

    sequence(:file_number, 100_000_000)
    sequence(:participant_id, 500_000_000)

    after(:build) do |veteran, evaluator|
      Fakes::BGSService.store_veteran_record(veteran.file_number, evaluator.bgs_veteran_record)
    end
  end
end
