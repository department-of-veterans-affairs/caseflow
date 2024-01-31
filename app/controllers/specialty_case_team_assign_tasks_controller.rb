# frozen_string_literal: true

class SpecialtyCaseTeamAssignTasksController < TasksController
  def create
    parent_task = parent_tasks_from_params.first
    if parent_task.closed?
      fail Caseflow::Error::ClosedTaskError
    end

    render json: { tasks: json_tasks(tasks.uniq) }
  end

  private

  def tasks
    @tasks ||= ActiveRecord::Base.transaction do
      create_params.map do |create_param|
        specialty_case_team_assign_task = SpecialtyCaseTeamAssignTask.find(create_param[:parent_id])

        # Even though this class was intended to be used with a judge assign task, It will work same with a
        # SpecialtyCaseTeamAssignTask since it essentially replaces the normal judge assign task
        AttorneyTaskCreator.new(specialty_case_team_assign_task, create_param).create_attorney_tasks_from_sct_params
      end.flatten
    end
  end
end
