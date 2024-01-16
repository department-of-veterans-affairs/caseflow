class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    Rails.logger.info("Auto Assign Correspondence Job was ran")
  end
end
