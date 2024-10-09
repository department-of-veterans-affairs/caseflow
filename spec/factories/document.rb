# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    sequence(:vbms_document_id, 10_000) { |n| "#{Time.zone.today.day}#{n}#{Time.zone.now.to_i.to_s.last(1)}" }

    type { "VA 8 Certification of Appeal" }
  end
end
