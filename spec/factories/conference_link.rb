# frozen_string_literal: true

FactoryBot.define do
  factory :conference_link do
    transient do
      conference_provider { "pexip" }
    end

    alias_name { nil }
    conference_id { nil }
    conference_deleted { false }
    host_pin { nil }
    host_link { nil }
    guest_pin_long { "6393596604" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    created_by { create(:user) }
    updated_by { create(:user) }
    meeting_type do
      create(:meeting_type, service_name: conference_provider)
    end

    factory :pexip_conference_link, class: PexipConferenceLink do
      type { "PexipConferenceLink" }
    end

    factory :webex_conference_link, class: WebexConferenceLink do
      type { "WebexConferenceLink" }
    end
  end
end
