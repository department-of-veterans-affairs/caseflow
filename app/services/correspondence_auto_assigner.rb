# frozen_string_literal: true

class CorrespondenceAutoAssigner
  def do_auto_assignment(current_user_id:)
    current_user = User.find(current_user_id)

    correspondence_auto_assign_logger.begin_logging
    unassigned_correspondences_task_id_pairs.each do |id_pair|
      create_review_package_task(
        correspondence_id: id_pair[0],
        task_id: id_pair[1],
        current_user: current_user
      )
    end
    correspondence_auto_assign_logger.end_logging
  end

  private

  def unassigned_correspondences_task_id_pairs
    Correspondence.joins(
      "INNER JOIN tasks ON tasks.appeal_id = correspondences.id"
    )
      .where("tasks.type" => "ReviewPackageTask")
      .where("tasks.status" => "unassigned")
      .order(va_date_of_receipt: :desc)
      .pluck("correspondences.id", "tasks.id")
  end

  def create_review_package_task(correspondence_id:, task_id:, current_user:)
    correspondence_auto_assign_logger.log_single_attempt(correspondence_id)
    unassigned_review_package_task = ReviewPackageTask.find(task_id)

    task_params = {
      parent_id: task_id,
      instructions: ["Auto assigned by #{current_user.css_id}"],
      assigned_to: InboundOpsTeam.singleton,
      appeal_id: correspondence_id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.assigned,
      type: ReassignPackageTask.name
    }

    ReviewPackageTask.create_from_params(task_params, current_user)
    unassigned_review_package_task.update!(assigned_to: InboundOpsTeam.singleton, status: :on_hold)

    correspondence_auto_assign_logger.record_success
  end

  def correspondence_auto_assign_logger
    @correspondence_auto_assign_logger ||= CorrespondenceAutoAssignLogger.new
  end
end
