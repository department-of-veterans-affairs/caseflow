# frozen_string_literal: true

##
# Task tracking work searching for decision documents related to VHA issues. CAMO coordinates this and can assign
# to a VHA Program office. When it's complete, they can return it to BVA Intake to recommend docketing or cancellation.

class VhaDocumentSearchTask < Task
  validates :parent, presence: true

  def available_actions(user)
    if assigned_to.user_has_access?(user) &&
       FeatureToggle.enabled?(:vha_predocket_workflow, user: RequestStore.store[:current_user])
      build_task_actions
    else
      []
    end
  end

  VHA_CAREGIVER_SUPPORT_TASK_ACTIONS = [
    # Mark task as in progress task action if it is assigned but not already in progress
    # status != Constants.TASK_STATUSES.in_progress ?
    #  Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS : nil
    # Return appeal to VHA CSP predocket queue task action?
    Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE.to_h
  ].compact.freeze

  VHA_CAMO_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.to_h,
    Constants.TASK_ACTIONS.VHA_SEND_TO_BOARD_INTAKE.to_h
  ].freeze

  def build_task_actions
    if assigned_to.is_a? VhaCaregiverSupport
      VHA_CAREGIVER_SUPPORT_TASK_ACTIONS
    else
      # Default to VhaCamo tasks since that was the original user of this type of task
      VHA_CAMO_TASK_ACTIONS
    end
  end

  def self.label
    COPY::REVIEW_DOCUMENTATION_TASK_LABEL
  end
end
