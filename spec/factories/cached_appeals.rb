# frozen_string_literal: true

FactoryBot.define do
  factory :cached_appeal, class: CachedAppeal do
    docket_number { rand(1000000..9999999) }
    docket_type { "evidence_submission" }
    appeal_type { Appeal.name } 
    appeal_id { rand(1000000..9999999) }
    vacols_id { nil }
  end
end
