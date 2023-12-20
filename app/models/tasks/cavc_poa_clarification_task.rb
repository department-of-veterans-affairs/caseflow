# frozen_string_literal: true

# Task for the CAVC Litigation Support team to clarify the Power of Attorney on a remand before sending the 90 day
# letter to the veteran
# Expected parent: SendCavcRemandProcessedLetterTask, CavcPoaClarificationTask
class CavcPoaClarificationTask < Task
  validates :parent,
            presence: true,
            parentTask: { task_types: [SendCavcRemandProcessedLetterTask, CavcPoaClarificationTask] },
            on: :create

  def self.label
    COPY::CAVC_POA_TASK_LABEL
  end

  def available_actions(user)
    super(user) - [Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h]
  end
end
