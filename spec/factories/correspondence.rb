# frozen_string_literal: true

FactoryBot.define do
  factory :correspondence do
    uuid { SecureRandom.uuid }
    portal_entry_date { Time.zone.now }
    source_type { "Mail" }
    package_document_type_id { 1250 }
    cmp_packet_number { rand(1_000_000_000..9_999_999_999) }
    va_date_of_receipt { Time.zone.yesterday }
    veteran_id { create(:veteran).id }
  end
end
