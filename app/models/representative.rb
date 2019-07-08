# frozen_string_literal: true

class Representative < Organization
  after_initialize :set_role

  def user_has_access?(user)
    return false unless user.roles.include?("VSO")

    participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }
    participant_ids.include?(participant_id)
  end

  def can_receive_task?(_task)
    false
  end

  def should_write_ihp?(appeal)
    ihp_writing_configs.include?(appeal.docket_type) && appeal.representatives.include?(self)
  end

  def queue_tabs
    [
      tracking_tasks_tab,
      unassigned_tasks_tab,
      assigned_tasks_tab,
      completed_tasks_tab
    ]
  end

  # TODO: Should this be offloaded to a new class (QueueTab?) since we're not referencing these fields in 3 classes?
  def tracking_tasks_tab
    {
      label: COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME,
      description: format(COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, name),
      columns: [
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
      ],
      allow_bulk_assign: false
    }
  end

  def ama_task_serializer
    WorkQueue::OrganizationTaskSerializer
  end

  private

  def set_role
    self.role = "VSO"
  end

  def ihp_writing_configs
    vso_config&.ihp_dockets || [Constants.AMA_DOCKETS.evidence_submission, Constants.AMA_DOCKETS.direct_review]
  end
end
