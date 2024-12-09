# frozen_string_literal: true

FactoryBot.define do
  factory :cmp_mail_packet do
    packet_uuid { Faker::Internet.uuid }
    cmp_packet_number { Faker::Number.number(digits: 10) }
    packet_source { Faker::Internet.username(specifier: 8) }
    va_dor { Time.current }
    veteran_id { Faker::Number.number(digits: 9) }
    veteran_first_name { Faker::Name.first_name }
    veteran_middle_initial { Faker::Name.initials(number: 1) }
    veteran_last_name { Faker::Name.last_name }
  end
end
