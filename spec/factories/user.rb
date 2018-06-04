FactoryBot.define do
  factory :user do
    sequence(:css_id) { |n| "CSS_ID#{n}" }

    station_id "283"
  end
end
