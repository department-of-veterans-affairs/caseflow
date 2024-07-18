# frozen_string_literal: true

class CorrespondenceDetailsController < CorrespondenceController
  include CorrespondenceControllerConcern
  include RunAsyncable

  before_action :correspondence
  before_action :correspondence_status

  def correspondence_details
    @correspondence = WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
    respond_to do |format|
      format.html {}
      format.json do
        render json: { correspondence: @correspondence, status: :ok }
      end
    end
  end

  def complete?
    CorrespondenceRootTask.completed
    # if children&.all?(&:completed?)

    # root task ids for all the assignee's tasks
    # potential_root_task_ids = correspondence.tasks.select(:parent_id)
    #   .where(status: Constants.TASK_STATUSES.completed).distinct.pluck(:parent_id)

    # # root task ids within the subset created above with open child tasks
    # ids_to_exclude = CorrespondenceTask.select(:parent_id)
    #   .where(parent_id: potential_root_task_ids)
    #   .open.distinct.pluck(:parent_id)

    # CorrespondenceRootTask.includes(*task_includes).where(id: potential_root_task_ids - ids_to_exclude)

    completed_root_task_ids = CorrespondenceRootTask.select(:id)
      .where(status: Constants.TASK_STATUSES.completed).pluck(:id)

    ids_with_completed_child_tasks = CorrespondenceTask.select(:parent_id)
      .where(status: Constants.TASK_STATUSES.completed)
      .where.not(type: CorrespondenceRootTask.name).distinct.pluck(:parent_id)

    ids_to_exclude = CorrespondenceTask.select(:parent_id)
      .where(parent_id: ids_with_completed_child_tasks)
      .open.distinct.pluck(:parent_id)

    CorrespondenceRootTask.where(id: completed_root_task_ids + ids_with_completed_child_tasks - ids_to_exclude)
  end

  def pending?
    CorrespondenceMailTask.active
    # CorrespondenceMailTask.includes(*task_includes).active
  end

  def correspondence_status
    return @correspondence_status = "Complete" if complete?
    return @correspondence_status = "Pending" if pending?

    @correspondence_status = "Error"
  end
end
