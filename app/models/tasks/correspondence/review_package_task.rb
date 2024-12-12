# frozen_string_literal: true

class ReviewPackageTask < CorrespondenceTask
  class << self
    def create_from_params(params, user)
      parent_task = ReviewPackageTask.find(params[:parent_id])
      # verify the user can create correspondence tasks
      verify_correspondence_access(user)
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

      params = modify_params_for_create(params)
      child = create_child_task(parent_task, user, params)
      parent_task.update!(status: params[:status]) if params[:status]
      child
    end
  end

  def when_child_task_created(_child_task)
    true
  end

  def task_url
    if closed?
      "/under_construction"
    else
      Constants.CORRESPONDENCE_TASK_URL.REVIEW_PACKAGE_TASK_URL.sub("uuid", correspondence.uuid)
    end
  end
end
