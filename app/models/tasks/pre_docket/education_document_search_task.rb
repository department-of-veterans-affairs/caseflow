# frozen_string_literal: true

# Task tracking work searching for decision documents related to Education issues.

class EducationDocumentSearchTask < Task
  validates :parent, presence: true

  def available_actions(user)
    if assigned_to.user_has_access?(user)
      TASK_ACTIONS
    else
      []
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.EMO_ASSIGN_TO_RPO.to_h,
    Constants.TASK_ACTIONS.EMO_RETURN_TO_BOARD_INTAKE.to_h,
    Constants.TASK_ACTIONS.EMO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.to_h
  ].freeze

  def self.label
    COPY::REVIEW_DOCUMENTATION_TASK_LABEL
  end
end
