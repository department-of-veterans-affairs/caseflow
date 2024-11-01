# frozen_string_literal: true

FactoryBot.define do
  factory :transcription_contractor do
    name { "Contractor Name" }
    directory { "directory" }
    email { "test@va.gov" }
    phone { "phone" }
    poc { "person of contact" }
  end
end
