# frozen_string_literal: true

FactoryBot.define do
  factory :returned_appeal_job do
    start { Time.zone.now }
    self.end { Time.zone.now + 1.hour }
    errored { nil }
    stats { { success: true, message: "Job completed successfully" }.to_json }
    returned_appeals { [] }
  end
end
