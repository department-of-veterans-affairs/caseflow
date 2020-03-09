# frozen_string_literal: true

##
# Endpoint to return ScheduleHearingTasks for Assign Hearings Table

class Hearings::ScheduleHearingTasksController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_build_hearing_schedule_access

  def index
    task_pager = Hearings::ScheduleHearingTaskPager.new(
      assignee: HearingsManagement.singleton,
      tab_name: allowed_params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym],
      page: allowed_params[Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM.to_sym],
      filters: allowed_params[Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM.to_sym],
      regional_office_key: allowed_params[:regional_office_key]
    )

    tasks = task_pager.paged_tasks

    render json: {
      tasks: json_tasks(tasks),
      tasks_per_page: TaskPager::TASKS_PER_PAGE,
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count
    }
  end

  private

  def allowed_params
    params.permit(
      Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym,
      Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM.to_sym,
      { Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM.to_sym => [] },
      :regional_office_key
    )
  end

  def json_tasks(tasks)
    AmaAndLegacyTaskSerializer.create_and_preload_legacy_appeals(
      tasks: tasks,
      params: { user: current_user },
      ama_serializer: WorkQueue::RegionalOfficeTaskSerializer
    ).call
  end
end
