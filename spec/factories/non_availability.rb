# frozen_string_literal: true

FactoryBot.define do
  factory :non_availability do
    date { Date.parse("2018-04-01") }
  end

  factory :co_non_availability, class: CoNonAvailability, parent: :non_availability do
    object_identifier { "CO" }
  end

  factory :ro_non_availability, class: RoNonAvailability, parent: :non_availability do
    object_identifier { "RO01" }
  end
end
