# frozen_string_literal: true

class HearingPostponementRequestMailTask < HearingRequestMailTask
  class << self
    # These should live in COPY.json
    def label
      "Hearing postponement request"
    end

    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(_user)
    TASK_ACTIONS
  end
end
