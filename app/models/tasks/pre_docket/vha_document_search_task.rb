# frozen_string_literal: true

##
# Task tracking work searching for decision documents related to VHA issues. CAMO coordinates this and can assign
# to a VHA Program office. When it's complete, they can return it to BVA Intake to recommend docketing or cancellation.

class VhaDocumentSearchTask < Task
  validates :parent, presence: true

  def available_actions(user)
    if assigned_to.user_has_access?(user) &&
       FeatureToggle.enabled?(:vha_predocket_workflow, user: RequestStore.store[:current_user])
      return VHA_CAMO_TASK_ACTIONS if assigned_to.is_a?(VhaCamo)
      return caregiver_actions if assigned_to.is_a?(VhaCaregiverSupport)
    else
      []
    end
  end

  VHA_CAREGIVER_SUPPORT_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW.to_h,
    Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE.to_h
  ].freeze

  VHA_CAMO_TASK_ACTIONS = [
    Constants.TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.to_h,
    Constants.TASK_ACTIONS.VHA_DOCUMENTS_READY_FOR_BVA_INTAKE_REVIEW.to_h,
    Constants.TASK_ACTIONS.VHA_RETURN_TO_BOARD_INTAKE.to_h
  ].freeze

  def self.label
    COPY::REVIEW_DOCUMENTATION_TASK_LABEL
  end

  private

  def caregiver_actions
    if status != Constants.TASK_STATUSES.in_progress
      [Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS.to_h] +
        VHA_CAREGIVER_SUPPORT_TASK_ACTIONS
    else
      VHA_CAREGIVER_SUPPORT_TASK_ACTIONS
    end
  end
end
