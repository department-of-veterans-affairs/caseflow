# frozen_string_literal: true

class Hearings::UpdateTranscriptionPackageStatusJob < ApplicationJob
  queue_with_priority :low_priority

  def perform
    update_overdue_for_assigned_packages
    update_overdue_for_completed_packages
    update_failed_retrieval_packages
  end

  private

  def update_overdue_for_assigned_packages
    TranscriptionPackage.where(status: "Sent")
      .where("expected_return_date > ?", Time.zone.now)
      .update_all(status: "Overdue")
  end

  def update_overdue_for_completed_packages
    TranscriptionPackage.where(status: "Completed")
      .where("returned_at > ?", Time.zone.now)
      .update_all(status: "Overdue")
  end

  def update_failed_retrieval_packages
    TranscriptionPackage.where(status: "Failed retrieval (BOX)")
      .update_all(status: "Retrieval failure")
  end
end
