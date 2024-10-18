# frozen_string_literal: true

namespace :remediations do
  desc "Cancel VeteranRecordRequest tasks that are both open and assigned to " \
       "the 'Veterans Readiness and Employment' business line"
  task cancel_vrr_tasks_open_for_vre: [:environment] do
    CancelTasksAndDescendants.call(
      VeteranRecordRequestsOpenForVREQuery.call
    )
  end
end
