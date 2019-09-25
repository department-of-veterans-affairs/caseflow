# frozen_string_literal: true

class AttorneyTaskCreator
  def initialize(judge_assign_task, task_params)
    @judge_assign_task = judge_assign_task
    @task_params = task_params
  end

  def call
    tasks
  end

  private

  attr_reader :judge_assign_task, :task_params

  def tasks
    judge_review_task = JudgeDecisionReviewTask.create!(judge_assign_task.slice(:appeal, :assigned_to, :parent))
    judge_assign_task.update!(status: Constants.TASK_STATUSES.completed)
    attorney_task = AttorneyTask.create!(task_params.merge(parent: judge_review_task))
    [attorney_task, judge_review_task, judge_assign_task]
  end
end
