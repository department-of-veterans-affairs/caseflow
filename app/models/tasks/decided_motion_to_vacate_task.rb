# frozen_string_literal: true

class DecidedMotionToVacateTask < Task
  self.abstract_class = true

  before_create :automatically_create_org_task

  def available_actions(user)
    actions = super(user)

    actions.push(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)

    actions
  end

  def update_status_if_children_tasks_are_closed(_child_task)
    if assigned_to.is_a?(Organization)
      return update!(status: :completed) unless all_children_cancelled?
    end

    super
  end

  def automatically_create_org_task
    if assigned_to.is_a?(Organization)
      return
    end

    org_task = dup.tap do |new_task|
      new_task.assigned_to_type = "Organization"
      new_task.assigned_to = org(assigned_by)
      new_task.save!
    end
    self.parent = org_task
  end

  def org(user)
    self.class.org(user)
  end

  class << self
    def org(_user)
      fail Caseflow::Error::MustImplementInSubclass
    end
  end
end
