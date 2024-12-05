# frozen_string_literal: true

FactoryBot.define do
  factory :correspondence_document do
    document_file_number { Faker::Number.within(range: 1000..999999) }
    pages { Faker::Number.within(range: 1..100) }
    uuid { Faker::Internet.uuid }

    document_type { Faker::Number.within(range: 10..1823 ) }
    vbms_document_type_id { document_type }

    correspondence
  end
end
