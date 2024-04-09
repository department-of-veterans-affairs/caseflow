# frozen_string_literal: true

FactoryBot.define do
  factory :batch_auto_assignment_attempt do
    created_at { 12.hours.ago }
    started_at { 12.hours.ago }
    updated_at { 12.hours.ago }
    status { Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started }

    association :user, factory: :user

    trait :packages_assigned do
      num_nod_packages_assigned { 5 }
      num_nod_packages_unassigned { 2 }
      num_packages_assigned { 8 }
      num_packages_unassigned { 3 }
    end

    trait :completed do
      status { Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed }
      completed_at { Time.current }
    end

    trait :max_capacity_error do
      status { Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error }
      error_info { { message: COPY::BAAA_USERS_MAX_QUEUE_REACHED } }
      errored_at { Time.current }
    end

    trait :no_correspondences_error do
      status { Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error }
      error_info { { message: COPY::BAAA_NO_UNASSIGNED_CORRESPONDENCE } }
      errored_at { Time.current }
      statistics { { seconds_elapsed: 1 } }
    end
  end
end
