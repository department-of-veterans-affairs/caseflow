# frozen_string_literal: true

# Task assigned to the Specialty Case Team organization from which one of the SCT Coordinators will assign the
# associated appeal to one of their attorneys by creating a couple of tasks (a JudgeDecisionReviewTask
# and an AttorneyTask) to draft a decision on the appeal.
#
# Task is created as a result of case distribution.
# Task should always have a RootTask as its parent.
# An active task will result in the case appearing in the Specialty Case Team bulk Assign View.
#
# Expected parent task: RootTask
#
# Expected child task: None

class SpecialtyCaseTeamAssignTask < Task
  validate :only_open_task_of_type, on: :create,
                                    unless: :skip_check_for_only_open_task_of_type

  def additional_available_actions(user)
    if assigned_to.user_has_access?(user)
      [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
    else
      []
    end
  end

  def self.label
    COPY::SPECIALTY_CASE_TEAM_ASSIGN_TASK_LABEL
  end
end
