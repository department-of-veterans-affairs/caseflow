# frozen_string_literal: true

FactoryBot.define do
  factory :cmp_document do
    packet_uuid { Faker::Internet.uuid }
    cmp_document_id { Faker::Internet.uuid }
    cmp_document_uuid { Faker::Internet.uuid }
    vbms_doctype_id { Faker::Number.within(range: 1..100) }
    doctype_name { Faker::Internet.username(specifier: 8) }
    date_of_receipt { Time.current }

    cmp_mail_packet
  end
end
