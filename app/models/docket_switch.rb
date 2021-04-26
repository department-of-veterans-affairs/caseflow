# frozen_string_literal: true

class DocketSwitch < CaseflowRecord
  belongs_to :old_docket_stream, class_name: "Appeal", optional: false
  belongs_to :new_docket_stream, class_name: "Appeal"
  belongs_to :task, optional: false

  attr_accessor :context, :selected_task_ids, :new_admin_actions

  validates :disposition, presence: true
  validate :granted_issues_present_if_partial

  delegate :request_issues, to: :old_docket_stream

  enum disposition: {
    granted: "granted",
    partially_granted: "partially_granted",
    denied: "denied"
  }

  scope :updated_since_for_appeals, lambda { |since|
    select(:old_docket_stream_id).where("#{table_name}.updated_at >= ?", since)
  }

  def process!
    process_denial! if denied?
    process_granted! if task.is_a?(DocketSwitchGrantedTask)
  end

  private

  def process_denial!
    new_instructions = task.instructions.push(context)

    DocketSwitch::TaskHandler.new(docket_switch: self).call

    task.update(status: Constants.TASK_STATUSES.completed, instructions: new_instructions)
  end

  def process_granted!
    transaction do
      new_stream = old_docket_stream.create_stream(:original).tap do |stream|
        stream.update!(docket_type: docket_type)
      end
      update!(new_docket_stream: new_stream)
      copy_granted_request_issues!

      DocketSwitch::TaskHandler.new(
        docket_switch: self,
        selected_task_ids: selected_task_ids,
        new_admin_actions: admin_actions_params
      ).call

      copy_ds_tasks_to_new_stream

      task.update(status: Constants.TASK_STATUSES.completed)
    end
  end

  def admin_actions_params
    (new_admin_actions || []).map { |data| data.permit(:instructions, :type).merge(assigned_by: task.assigned_to) }
  end

  def request_issues_for_switch
    return [] if denied?

    issue_ids = [*granted_request_issue_ids].presence || old_docket_stream.request_issues.map(&:id)
    RequestIssue.find(issue_ids)
  end

  def copy_granted_request_issues!
    request_issues_for_switch.each do |ri|
      ri.move_stream!(new_appeal_stream: new_docket_stream, closed_status: "docket_switch")
    end
  end

  def granted_issues_present_if_partial
    return unless partially_granted?

    unless granted_request_issue_ids
      errors.add(
        :granted_request_issue_ids,
        "is required for partially_granted disposition"
      )
    end
  end

  # We want the granted/denied tasks to be visible on the new stream as well as the old to give user context
  def copy_ds_tasks_to_new_stream
    new_completed_task = DocketSwitchGrantedTask.assigned_to_any_user.find_by(appeal: old_docket_stream).dup
    new_completed_task.assign_attributes(
      appeal_id: new_docket_stream.id,
      parent_id: new_docket_stream.root_task.id,
      status: Constants.TASK_STATUSES.completed
    )
    # Disable validation to avoid errors re creating with status of completed
    new_completed_task.save(validate: false)
  end
end
