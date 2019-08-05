# frozen_string_literal: true

##
# Task for a judge to assign tasks to attorneys.

class JudgeAssignTask < JudgeTask
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

  def label
    COPY::JUDGE_ASSIGN_TASK_LABEL
  end

  def hide_from_case_timeline
    true
  end
end
