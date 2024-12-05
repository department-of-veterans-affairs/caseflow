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
    TranscriptionPackage.where(status: COPY::TRANSCRIPTION_STATUS_SENT_FILTER_OPTION)
      .where("expected_return_date > ?", Time.zone.now)
      .update_all(status: COPY::TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION)
  end

  def update_overdue_for_completed_packages
    TranscriptionPackage.where(status: COPY::TRANSCRIPTION_DISPATCH_COMPLETED_TAB)
      .where("returned_at > ?", Time.zone.now)
      .update_all(status: COPY::TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION)
  end

  def update_failed_retrieval_packages
    TranscriptionPackage.where(status: COPY::TRANSCRIPTION_STATUS_RETRIEVAL_FAILURE_FILTER_VALUE)
      .update_all(status: COPY::TRANSCRIPTION_STATUS_RETRIEVAL_FAILURE_FILTER_OPTION)
  end
end
