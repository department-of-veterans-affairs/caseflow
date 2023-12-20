# frozen_string_literal: true

FactoryBot.define do
  factory :unrecognized_party_detail do
    party_type { "individual" }
    name { "Jane" }
    last_name { "Smith" }
    address_line_1 { "123 Park Ave" }
    city { "Springfield" }
    state { "NY" }
    zip { "12345" }
    country { "USA" }

    trait :individual do
      party_type { "individual" }
      name { "Jane" }
      last_name { "Smith" }
    end

    trait :organization do
      party_type { "organization" }
      name { "Steinberg and Sons" }
      last_name { nil }
    end
  end
end
