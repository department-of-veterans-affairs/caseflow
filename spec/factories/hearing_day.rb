# frozen_string_literal: true

FactoryBot.define do
  factory :hearing_day do
    transient do
      creating_user { create(:user) }
      updating_user { create(:user) }
    end

    scheduled_for { Date.tomorrow }
    request_type { HearingDay::REQUEST_TYPES[:central] }
    room { "2" }
    created_by { creating_user.css_id }
    updated_by { updating_user.css_id }
    created_by_id { creating_user.id }
    updated_by_id { updating_user.id }
  end
end
