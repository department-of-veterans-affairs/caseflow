# frozen_string_literal: true

class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    Rails.logger.info("Auto assign correspondences job.....")
    unassigned_correspondences = Correspondence.joins("INNER JOIN tasks ON tasks.appeal_id = correspondences.id")
      .where("tasks.status" => "unassigned")
      .where("tasks.appeal_type" => "Correspondence")
      .order(va_date_of_receipt: :desc)
    unassigned_correspondences.each do |unassigned_correspondence|
      begin
        unassigned_correspondence.update!(assigned_to: MailTeamSupervisor.singleton)
      rescue ActiveRecord::RecordInvalid => error
        invalid_record_error(error.record)
      end
    end
  end
end
