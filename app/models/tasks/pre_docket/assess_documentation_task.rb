# frozen_string_literal: true

##
# Task that is assigned to either a VhaProgramOffice, or VhaRegionalOffice organizations for them to locate
# the appropriate documents for an appeal. This task would normally move from CAMO -> Program -> Regional however it
# will also need to move up the chain as well i.e. Regional -> Program etc.

class AssessDocumentationTask < Task
  validates :parent, presence: true,
                     on: :create

  # Actions that can be taken on both organization and user tasks
  DEFAULT_ACTIONS = [
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
  ].freeze

  PO_ACTIONS = [
    Constants.TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.to_h,
    Constants.TASK_ACTIONS.VHA_PO_SEND_TO_CAMO_FOR_REVIEW.to_h
  ].freeze

  RO_ACTIONS = [
    Constants.TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.to_h,
    Constants.TASK_ACTIONS.VHA_VISN_SEND_TO_VHA_PO_FOR_REVIEW.to_h
  ].freeze

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    task_actions = Array.new(DEFAULT_ACTIONS)

    if assigned_to.is_a?(VhaProgramOffice)
      if FeatureToggle.enabled?(:visn_predocket_workflow, user: user)
        task_actions.concat([Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h].freeze)
      end
      task_actions.concat(PO_ACTIONS)
    end

    if assigned_to.is_a?(VhaRegionalOffice)
      task_actions.concat(RO_ACTIONS)
    end

    if appeal.tasks.in_progress.none? { |task| task.is_a?(AssessDocumentationTask) }
      task_actions.concat([Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.to_h].freeze)
    end

    sort_task_actions(task_actions)
  end

  def self.label
    COPY::ASSESS_DOCUMENTATION_TASK_LABEL
  end

  private

  def sort_task_actions(task_actions)
    sorted_task_actions = []
    task_actions.each_with_index do |action, index|
      new_index = action.key?(:sort_order) ? action[:sort_order] : index
      sorted_task_actions.insert(new_index, action)
    end
    sorted_task_actions.compact!
  end
end
