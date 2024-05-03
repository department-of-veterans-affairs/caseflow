# frozen_string_literal: true

FactoryBot.define do
  factory :individual_auto_assignment_attempt do
    status { Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started }
    nod { false }
    statistics { nil }

    started_at { nil }
    completed_at { nil }
    errored_at { nil }

    association :batch_auto_assignment_attempt, factory: :batch_auto_assignment_attempt
    association :correspondence, factory: :correspondence
    association :user, factory: :user
  end
end
