# frozen_string_literal: true

FactoryBot.define do
  factory :task_timer do
    association :task, factory: :task
    last_submitted_at { Time.zone.now }
    submitted_at { Time.zone.now }
  end
end
