FactoryBot.define do
  factory :user do
    sequence(:css_id) { |n| "CSS_ID#{n}" }

    station_id "283"

    factory :default_user do
      css_id "DSUSER"
      full_name "Lauren Roth"
      email "test@example.com"
      roles ["Certify Appeal"]
    end
  end
end
