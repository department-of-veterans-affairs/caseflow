# frozen_string_literal: true

FactoryBot.define do
  factory :cached_appeal, class: CachedAppeal do
    docket_number { rand(1_000_000..9_999_999) }
    docket_type { Constants.AMA_DOCKETS.evidence_submission }
    appeal_type { Appeal.name }
    case_type { "Original" }
    is_aod { false }
    appeal_id { rand(1..9_999) }
    assignee_label  { "BVAAABSHIRE" }
    vacols_id { nil }
  end
end
