# frozen_string_literal: true

class DocketSwitch < CaseflowRecord
  belongs_to :old_docket_stream, class_name: "Appeal", optional: false
  belongs_to :new_docket_stream, class_name: "Appeal"
  belongs_to :task, optional: false

  attr_accessor :context, :old_tasks, :new_task_types

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
    task.update(status: Constants.TASK_STATUSES.completed, instructions: new_instructions)
  end

  def process_granted!
    transaction do
      update!(new_docket_stream: old_docket_stream.create_stream(:original))
      copy_granted_request_issues!
      DocketSwitchTaskHandler.new(docket_switch: self, old_tasks: old_tasks, new_task_types: new_task_types).process!
      task.update(status: Constants.TASK_STATUSES.completed)
    end
  end

  def request_issues_for_switch
    return if denied?

    issue_ids = granted_request_issue_ids || old_docket_stream.request_issues.map(&:id)
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
end
