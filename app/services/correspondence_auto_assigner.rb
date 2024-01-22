# frozen_string_literal: true

class CorrespondenceAutoAssigner
  def do_auto_assignment(current_user_id:)
    current_user = User.find(current_user_id)

    unassigned_correspondences_task_id_pairs.each do |id_pair|
      create_review_package_task(
        correspondence_id: id_pair[0],
        task_id: id_pair[1],
        current_user: current_user
      )
    end
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

    assign_user_review_package_task(user: current_user, task_params: task_params)
    unassigned_review_package_task.update!(assigned_to: InboundOpsTeam.singleton, status: :on_hold)
  end

  def assign_user_review_package_task(user:, task_params:)
    return unless permission_checker.can?(
      permission_name: Constants.ORGANIZATION_PERMISSIONS.auto_assign,
      organization: InboundOpsTeam.singleton,
      user: user
    )

    ReviewPackageTask.create_from_params(task_params, current_user)
  end

  def permission_checker
    @permission_checker ||= OrganizationUserPermissionChecker.new
  end
end
