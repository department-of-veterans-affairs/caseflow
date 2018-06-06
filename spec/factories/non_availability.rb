FactoryBot.define do
  factory :non_availability do
    date { Date.parse("2018-04-01") }
    object_identifier { "CO" }
  end

  factory :co_non_availability, class: CoNonAvailability, parent: :non_availability do
  end
end

