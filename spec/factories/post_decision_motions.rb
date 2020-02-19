# frozen_string_literal: true

FactoryBot.define do
  factory :post_decision_motion do
    appeal { create(:appeal) }
    disposition { "granted" }
    vacate_type { "straight_vacate" }

    before(:create) do |post_decision_motion|
      appeal = post_decision_motion.appeal
      next unless appeal.reload.decision_issues.empty?

      3.times do |idx|
        create(
          :decision_issue,
          :rating,
          decision_review: appeal,
          disposition: "denied",
          description: "Decision issue description #{idx}",
          decision_text: "decision issue"
        )
      end
    end
  end
end
