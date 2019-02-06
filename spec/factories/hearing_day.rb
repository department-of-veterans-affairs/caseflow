FactoryBot.define do
  factory :hearing_day do
    scheduled_for { Date.new(2019, 3, 2) }
    request_type { HearingDay::REQUEST_TYPES[:central] }
    room { "2" }
    created_by { create(:user).css_id }
    updated_by { create(:user).css_id }
  end
end
