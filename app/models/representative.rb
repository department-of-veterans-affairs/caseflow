# frozen_string_literal: true

class Representative < Organization
  after_initialize :set_role

  def user_has_access?(user)
    return false unless user.vso_employee?

    participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }
    participant_ids.include?(participant_id)
  end

  def can_receive_task?(_task)
    false
  end

  def show_reader_link_column?
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

  def tracking_tasks_tab
    ::OrganizationTrackingTasksTab.new(assignee: self)
  end

  private

  def set_role
    self.role = "VSO"
  end

  def ihp_writing_configs
    vso_config&.ihp_dockets || [Constants.AMA_DOCKETS.evidence_submission, Constants.AMA_DOCKETS.direct_review]
  end
end
