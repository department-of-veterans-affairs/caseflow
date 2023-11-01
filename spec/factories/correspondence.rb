# frozen_string_literal: true

FactoryBot.define do
  factory :correspondence do
    uuid { SecureRandom.uuid }
    portal_entry_date { Time.zone.now }
    source_type { "Mail" }
    package_document_type_id { 15 }
    correspondence_type_id { 9 }
    cmp_queue_id { 1 }
    cmp_packet_number { rand(1_000_000_000..9_999_999_999) }
    va_date_of_receipt { Time.zone.yesterday }
    prior_correspondence_id { 1 }
    notes { "This is a note from CMP." }
    assigned_by_id { 81 }
    veteran_id { 1 }
  end

  factory :correspondence_document do
    uuid { SecureRandom.uuid }
    vbms_document_id { "1250" }
  end
end
