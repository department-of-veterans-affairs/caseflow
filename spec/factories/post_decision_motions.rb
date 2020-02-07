# frozen_string_literal: true

FactoryBot.define do
  factory :post_decision_motion do
    task { create(:judge_address_motion_to_vacate_task) }
    disposition { "granted" }
    vacate_type { "straight_vacate" }

    before(:create) do |post_decision_motion|
      appeal = post_decision_motion.task.appeal
      return unless appeal.reload.decision_issues.empty?

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
