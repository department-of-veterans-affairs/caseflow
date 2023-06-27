# frozen_string_literal: true

require_relative "../../../lib/helpers/cancel_tasks_and_descendants"

namespace :remediations do
  desc "Cancel VeteranRecordRequest tasks that are both open and assigned to " \
       "the 'Veterans Readiness and Employment' business line"
  task :cancel_vrr_tasks_open_for_vre => [:environment] do
    CancelTasksAndDescendants.call(
      VeteranRecordRequestsOpenForVREQuery.call
    )
  end
end
