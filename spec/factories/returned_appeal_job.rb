# frozen_string_literal: true

FactoryBot.define do
  factory :returned_appeal_job do
    started_at { Time.zone.now }
    completed_at { Time.zone.now + 1.hour }
    errored_at { nil }
    stats { { success: true, message: "Job completed successfully" }.to_json }
    returned_appeals { [] }
  end
end
