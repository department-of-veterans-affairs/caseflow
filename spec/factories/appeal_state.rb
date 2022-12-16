# frozen_string_literal: true

FactoryBot.define do
  factory :appeal_state do
    appeal_id { nil }
    appeal_type { nil }
    created_at { Time.zone.now - 5.hours }
    created_by_id { User.first.id }
    updated_at { Time.zone.now }
    updated_by_id { User.first.id }
    appeal_docketed { false }
    privacy_act_pending { false }
    privacy_act_complete { false }
    vso_ihp_pending { false }
    vso_ihp_complete { false }
    hearing_scheduled { false }
    hearing_postponed { false }
    hearing_withdrawn { false }
    decision_mailed { false }
    appeal_cancelled { false }
    scheduled_in_error { false }
  end
end
