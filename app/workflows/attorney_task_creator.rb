# frozen_string_literal: true

class AttorneyTaskCreator
  def initialize(judge_assign_task, task_params)
    @judge_assign_task = judge_assign_task
    @task_params = task_params
  end

  def call
    tasks
  end

  def create_attorney_tasks_from_sct_params
    tasks_from_specialty_case_team_assign_task
  end

  private

  attr_reader :judge_assign_task, :task_params

  def tasks
    judge_review_task = JudgeDecisionReviewTask.create!(
      judge_assign_task.slice(:appeal, :assigned_to, :parent).merge(assigned_by: task_params[:assigned_by])
    )
    judge_assign_task.update!(status: Constants.TASK_STATUSES.completed)
    attorney_task = AttorneyTask.create!(Task.modify_params_for_create(task_params.merge(parent: judge_review_task)))
    [attorney_task, judge_review_task, judge_assign_task]
  end

  def tasks_from_specialty_case_team_assign_task
    # The judge assign task in this context is really a SpecialtyCaseTeamAssignTask
    # TODO: Return an error if there is no assigned to id or something
    assigned_attorney = User.find(task_params[:assigned_to_id])

    # TODO: this is trash
    attorney_judge = assigned_attorney.non_administered_judge_teams.map(&:organization).map(&:judge).sample

    judge_review_task = JudgeDecisionReviewTask.create!(
      judge_assign_task.slice(:appeal, :parent)
        .merge(assigned_by: task_params[:assigned_by], assigned_to: attorney_judge)
    )

    judge_assign_task.update!(status: Constants.TASK_STATUSES.completed)
    attorney_task = AttorneyTask.create!(Task.modify_params_for_create(task_params.merge(parent: judge_review_task,
                                                                                         assigned_by: attorney_judge)))
    [attorney_task, judge_review_task, judge_assign_task]
  end
end
