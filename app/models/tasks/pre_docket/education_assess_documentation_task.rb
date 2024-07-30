# frozen_string_literal: true

# Task that is assigned to an EducationRpo organization for them to locate
# the appropriate documents for an appeal.

class EducationAssessDocumentationTask < Task
  validates :parent, presence: true,
                     on: :create

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.to_h,
    Constants.TASK_ACTIONS.EDUCATION_RPO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.to_h
  ].freeze

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    task_actions = Array.new(TASK_ACTIONS)
    # VHA uses this to only mark in progress if task is not yet in progress
    if appeal.tasks.in_progress.none? { |task| task.is_a?(EducationAssessDocumentationTask) }
      task_actions.concat([Constants.TASK_ACTIONS.EDUCATION_RPO_MARK_TASK_IN_PROGRESS.to_h].freeze)
    end

    task_actions
  end

  def self.label
    COPY::ASSESS_DOCUMENTATION_TASK_LABEL
  end
end
