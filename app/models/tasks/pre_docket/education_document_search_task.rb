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
    # commented out because the method is not yet created
    # Constants.TASK_ACTIONS.EDUCATION_ASSIGN_TO_RPO.to_h,
    Constants.TASK_ACTIONS.EMO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.to_h
  ].freeze

  def self.label
    COPY::REVIEW_DOCUMENTATION_TASK_LABEL
  end
end
