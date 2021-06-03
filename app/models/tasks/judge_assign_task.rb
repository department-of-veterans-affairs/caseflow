# frozen_string_literal: true

##
# Task assigned to judge from which they will assign the associated appeal to one of their attorneys by creating a
# task (an AttorneyTask but not any of its subclasses) to draft a decision on the appeal.
# Task is created as a result of case distribution.
# Task should always have a RootTask as its parent.
# Task can one or more AttorneyTask children, one or more ColocatedTask children, or no child tasks at all.
# An open task will result in the case appearing in the Judge Assign View.
#
# Expected parent task: RootTask
#
# Expected child task: JudgeAssignTask can have one or more ColocatedTask children or no child tasks at all.
# Historically, it can have AttorneyTask children, but AttorneyTasks should now be under JudgeDecisionReviewTasks.

class JudgeAssignTask < JudgeTask
  validate :no_multiples_of_open_task_type, on: :create,
                                            if: :open_task_count_validation_required?

  def additional_available_actions(_user)
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h]
  end

  def begin_decision_review_phase
    update!(type: JudgeDecisionReviewTask.name)

    # Tell sentry so we know this is still happening. Remove this in a month
    msg = "Still changing JudgeAssignTask type to JudgeDecisionReviewTask."\
          "See: https://github.com/department-of-veterans-affairs/caseflow/pull/11140#discussion_r295487938"
    Raven.capture_message(msg, extra: { application: "tasks" }) if Time.zone.now > Time.zone.local(2019, 9, 1)
  end

  def self.label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end

  def hide_from_case_timeline
    true
  end
end
