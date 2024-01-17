# frozen_string_literal: true

class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    Rails.logger.info("Auto assign correspondences job.....")
  end
end
