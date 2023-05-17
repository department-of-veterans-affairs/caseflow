# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_distribution_destination do
    t.string "address_line_1", null: false, comment: "PII. If destination_type is domestic, international, or military then Must not be null."
    t.string "address_line_2", comment: "PII. If treatLine2AsAddressee is [true] then must not be null"
    t.string "address_line_3", comment: "PII. If treatLine3AsAddressee is [true] then must not be null"
    t.string "address_line_4", comment: "PII."
    t.string "address_line_5", comment: "PII."
    t.string "address_line_6", comment: "PII."
    t.string "city", comment: "PII. If type is [domestic, international, military] then Must not be null"
    t.string "country_code", comment: "Must be exactly two-letter ISO 3166 code."
    t.string "country_name"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "destination_type", null: false, comment: "Must be 'domesticAddress', 'internationalAddress', 'militaryAddress', 'derived', 'email', or 'sms'. Cannot be 'physicalAddress'."
    t.string "email_address"
    t.string "phone_number", comment: "PII."
    t.string "postal_code"
    t.string "state", comment: "PII. Must be exactly two-letter ISO 3166-2 code. If destination_type is domestic or military then Must not be null"
    t.boolean "treat_line_2_as_addressee"
    t.boolean "treat_line_3_as_addressee"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "vbms_distribution_id"
  end
end
