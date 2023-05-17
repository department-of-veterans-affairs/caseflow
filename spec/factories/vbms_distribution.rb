# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_distribution do
    t.string "claimant_station_of_jurisdiction", comment: "Can't be null if [recipient_type] is ro-colocated."
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "first_name", comment: "recipient's first name. If Type is [person] then it cant be null."
    t.string "last_name", comment: "recipient's last name. If Type is [person] then it cant be null."
    t.string "middle_name", comment: "recipient's middle name."
    t.string "name", comment: "should only be used for non-person entity names. Not null if [recipient_type] is organization, ro-colocated, or System."
    t.string "participant_id", comment: "recipient's participant id."
    t.string "poa_code", comment: "Can't be null if [recipient_type] is ro-colocated. The recipients POA code"
    t.string "recipient_type", null: false, comment: "Must be one of [person, organization, ro-colocated, System]."
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "vbms_communication_package_id"
  end
end
