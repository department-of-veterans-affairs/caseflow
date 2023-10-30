# frozen_string_literal: true

FactoryBot.define do
  factory :correspondence do
    portal_entry_date { Time.zone.today }
    source_type { "dummy" }
    package_document_type_id { 1 }
    cmp_packet_number { "dummy" }
    cmp_queue_id { 1 }
    uuid { SecureRandom.uuid }
    va_date_of_receipt { Time.zone.today }
    veteran_id { 1 }
    notes { "dummy" }
    correspondence_type_id { 1 }
    assigned_by_id { 1 }
    updated_by_id { 1 }
    prior_correspondence_id { 1 }
  end
end
