# frozen_string_literal: true

FactoryBot.define do
  factory :veteran do
    first_name { "Bob" }
    last_name { "Smith#{Faker::Name.last_name.downcase.tr('\'', '')}" }
    name_suffix { (bob_smith_count == 1) ? "II" : bob_smith_count.to_s }
    ssn { Generators::Random.unique_ssn }
    email_address { "#{first_name}.#{last_name}@test.com" }
    date_of_death { nil }

    transient do
      sequence(:bob_smith_count)
      sex { Faker::Gender.short_binary_type.upcase }
      bgs_veteran_record do
        {
          first_name: first_name,
          last_name: last_name,
          date_of_birth: 30.years.ago.to_date.strftime("%m/%d/%Y"),
          date_of_death: date_of_death,
          name_suffix: name_suffix,
          sex: sex,
          address_line1: "1234 Main Street",
          country: "USA",
          zip_code: "12345",
          state: "FL",
          city: "Orlando"
        }
      end
    end

    sequence(:file_number, 100_000_000)
    sequence(:participant_id, 500_000_000)

    after(:build) do |veteran, evaluator|
      Fakes::BGSService.store_veteran_record(
        veteran.file_number,
        evaluator.bgs_veteran_record.merge(
          file_number: veteran.file_number,
          ssn: veteran.ssn,
          email_address: evaluator.email_address,
          date_of_death: veteran.date_of_death,
          # both for compatability
          ptcpnt_id: veteran.participant_id,
          participant_id: veteran.participant_id
        )
      )
    end
  end
end
