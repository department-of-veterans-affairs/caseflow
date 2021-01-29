# frozen_string_literal: true

##
# Endpoint to return ScheduleHearingTasks for Assign Hearings Table

class Hearings::ScheduleHearingTasksController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_edit_hearing_schedule_access

  def index
    task_pager = Hearings::ScheduleHearingTaskPager.new(
      assignee: HearingsManagement.singleton,
      tab_name: allowed_params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM],
      page: allowed_params[Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM].to_i,
      filters: allowed_params[Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM],
      regional_office_key: allowed_params[:regional_office_key]
    )

    # Select `power_of_attorney_name`, `hearing_request_type`, and
    # `former_travel` from the `CachedAppeal` table. This is an
    # optimization that fetches these values from the `CachedAppeal` table,
    # where they are already cached for filtering. The `TaskColumnSerializer` is
    # "aware" of these optimizations, and will serialize the cached values instead
    # of getting them through the `Appeal` instance.
    tasks = task_pager
      .paged_tasks
      .select(
        "tasks.*,
        #{CachedAppeal.table_name}.power_of_attorney_name,
        #{CachedAppeal.table_name}.hearing_request_type,
        #{CachedAppeal.table_name}.former_travel"
      )

    render json: {
      tasks: json_tasks(tasks),
      tasks_per_page: TaskPager::TASKS_PER_PAGE,
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      docket_line_index: task_pager.docket_line_index
    }
  end

  private

  def allowed_params
    params.permit(
      Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM,
      Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM,
      { Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM => [] },
      :regional_office_key
    )
  end

  def json_tasks(tasks)
    primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)

    WorkQueue::TaskColumnSerializer.new(
      primed_tasks,
      is_collection: true,
      params: { columns: AssignHearingTab.serialize_columns }
    ).serializable_hash
  end
end
