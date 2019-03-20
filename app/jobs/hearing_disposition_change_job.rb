# frozen_string_literal: true

class HearingDispositionChangeJob < CaseflowJob
  queue_as :low_priority

  def perform
    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    disposition_task_changer = HearingDispositionTaskChanger.new
    disposition_task_changer.run
    disposition_task_changer.publish_results
  end
end
