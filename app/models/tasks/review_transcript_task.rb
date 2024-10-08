# frozen_string_literal: true

class ReviewTranscriptTask < Task

  USER_ACTIONS = [
    Constants.TASK_ACTIONS.TRANSCRIPT_NO_ERRORS_FOUND.to_h,
    Constants.TASK_ACTIONS.TRANSCRIPT_ERRORS_FOUND_AND_CORRECTED.to_h,
    Constants.TASK_ACTIONS.CANCEL_REVIEW_TRANSCRIPT_TASK.to_h,
  ].freeze

  def label
    COPY::REVIEW_TRANSCRIPT_TASK_LABEL
  end

  def available_actions(user)
    return USER_ACTIONS if assigned_to == user
    []
  end

  def default_instructions
    "Review the hearing transcript and upload the final to VBMS once it has been reviewed for errors or corrected."
  end
end
