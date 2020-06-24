# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    sequence(:vbms_document_id, 10_000) # start with initial high value to reserve manual assignment range

    type { "VA 8 Certification of Appeal" }
  end
end
