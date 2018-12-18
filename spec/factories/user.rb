FactoryBot.define do
  factory :user do
    sequence(:css_id) { |n| "CSS_ID#{n}" }

    station_id User::BOARD_STATION_ID
    full_name { "Lauren Roth" }

    factory :default_user do
      css_id "DSUSER"
      full_name "Lauren Roth"
      email "test@example.com"
      roles ["Certify Appeal"]
    end

    factory :hearings_coordinator do
      css_id "BVATWARNER"
      full_name "Thomas Warner"
      email "thomas.warner@example.com"
      roles ["Assign Hearings"]
    end

    trait :vso_role do
      roles ["VSO"]
    end
  end
end
