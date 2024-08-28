# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    vbms_document_id { (10_000..999_999).to_a.sample }
    type { "VA 8 Certification of Appeal" }
  end
end
