# frozen_string_literal: true

class LegacyTasksController < ApplicationController
  include Errors

  ROLES = Constants::USER_ROLE_TYPES.keys.freeze

  rescue_from Caseflow::Error::LegacyCaseAlreadyAssignedError do |e|
    handle_non_critical_error("legacy_tasks", e)
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    fail(Caseflow::Error::InvalidUserId, user_id: params[:user_id]) unless user

    user_role = (params[:role] || user.vacols_roles.first).try(:downcase)
    return invalid_role_error unless ROLES.include?(user_role)

    respond_to do |format|
      format.html do
        render "queue/index"
      end
      format.json do
        MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                              name: "LegacyTasksController.index") do
          tasks = LegacyWorkQueue.tasks_for_user(user)
          render json: {
            tasks: json_tasks(tasks, user, user_role)
          }
        end
      end
    end
  end

  def create
    if assigned_to&.vacols_roles&.length == 1 && assigned_to.judge_in_vacols?
      return assign_to_judge
    end

    # return [AttorneyTask, JudgeAssignTask]
    if DasDeprecation::AssignTaskToAttorney.should_perform_workflow?(legacy_task_params[:appeal_id])
      return create_with_das
    end

    task = JudgeCaseAssignmentToAttorney.create(legacy_task_params)
    return invalid_record_error(task) unless task.valid?

    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(
                        task.last_case_assignment,
                        LegacyAppeal.find_or_create_by_vacols_id(task.vacols_id),
                        task.assigned_to
                      ))
    }
  end

  def assign_to_judge
    # If the user being assigned to is a judge, do not create a DECASS record, just
    # update the location to the assigned judge.
    QueueRepository.update_location_to_judge(appeal.vacols_id, assigned_to)

    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(
                        VACOLS::CaseAssignment.latest_task_for_appeal(appeal.vacols_id),
                        appeal,
                        assigned_to
                      ))
    }
  end

  def update
    if DasDeprecation::AssignTaskToAttorney.should_perform_workflow?(legacy_task_params[:appeal_id])
      return reassign_with_das
    end

    task = JudgeCaseAssignmentToAttorney.update(legacy_task_params.merge(task_id: params[:id]))

    return invalid_record_error(task) unless task.valid?

    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(
                        task.last_case_assignment,
                        LegacyAppeal.find_or_create_by_vacols_id(task.vacols_id),
                        task.assigned_to
                      ))
    }
  end

  private

  def user
    @user ||= begin
                return User.find(params[:user_id]) if positive_integer?(params[:user_id])

                User.find_by(css_id: params[:user_id])
              end
  end
  helper_method :user

  def positive_integer?(param)
    /\A\d+\z/.match(param)
  end

  def appeal
    @appeal ||= LegacyAppeal.find(legacy_task_params[:appeal_id])
  end

  def legacy_task_params
    params.require("tasks")
      .permit(:appeal_id)
      .merge(assigned_by: current_user)
      .merge(assigned_to: User.find_by(id: params[:tasks][:assigned_to_id]))
      .merge(judge: User.find_by(id: params[:tasks][:judge_id] || current_user.id))
  end

  def json_task(task)
    ::WorkQueue::LegacyTaskSerializer.new(task)
  end

  def json_tasks(tasks, user, role)
    ::WorkQueue::LegacyTaskSerializer.new(tasks, is_collection: true, params: { user: user, role: role })
  end

  def current_role
    (params[:role] || current_user.vacols_roles.first).try(:downcase)
  end

  def assigned_to
    legacy_task_params[:assigned_to]
  end

  def create_with_das
    tasks = DasDeprecation::AssignTaskToAttorney.create_attorney_task(appeal.vacols_id, current_user, assigned_to)
    params = { user: current_user, role: current_role }

    render json: {
      tasks: ::WorkQueue::TaskSerializer.new(tasks, is_collection: true, params: params)
    }
  end

  def reassign_with_das
    task = DasDeprecation::AssignTaskToAttorney.reassign_attorney_task(appeal.vacols_id, current_user, assigned_to)

    render json: {
      task: ::WorkQueue::TaskSerializer.new(task)
    }
  end
end
