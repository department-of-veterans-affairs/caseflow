# frozen_string_literal: true

class AutoAssignCorrespondenceJob < CaseflowJob
  queue_with_priority :low_priority

  # rubocop:disable Metrics/MethodLength
  def perform
    Rails.logger.info("Auto assign correspondences job in progress.....")

    # An array of [correspondence.id, task.id]
    unassigned_correspondences_task_id_pairs = Correspondence.joins(
      "INNER JOIN tasks ON tasks.appeal_id = correspondences.id"
    )
      .where("tasks.type" => "ReviewPackageTask")
      .where("tasks.status" => "unassigned")
      .order(va_date_of_receipt: :desc)
      .pluck("correspondences.id", "tasks.id")

    unassigned_correspondences_task_id_pairs.each do |id_pair|
      begin
        unassigned_review_package_task = ReviewPackageTask.find(id_pair[1])
        task_params = {
          parent_id: id_pair[1],
          instructions: ["Auto assigned by #{RequestStore[:current_user]}"],
          assigned_to: InboundOpsTeam.singleton,
          appeal_id: id_pair[0],
          appeal_type: "Correspondence",
          status: Constants.TASK_STATUSES.assigned,
          type: ReassignPackageTask.name
        }
        ReviewPackageTask.create_from_params(task_params, RequestStore[:current_user])
        unassigned_review_package_task.update!(assigned_to: InboundOpsTeam.singleton, status: :on_hold)
      rescue ActiveRecord::RecordInvalid => error
        invalid_record_error(error.record)
      end
    end
    Rails.logger.info("Auto assign correspondences job resolved.")
  end
  # rubocop:enable Metrics/MethodLength
end


