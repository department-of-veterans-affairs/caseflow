# frozen_string_literal: true

class Organizations::TaskPagesController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  # /organizations/{org.url}/task_pages?
  #   tab=on_hold&
  #   sort_by=case_details_link&
  #   order=desc&
  #   filter[]=col%3Ddocket_type%26val%3Dlegacy&
  #   filter[]=col%3Dtask_action%26val%3Dtranslation&
  #   page=3
  #
  # params = <ActionController::Parameters {
  #   "tab"=>"on_hold",
  #   "sort_by"=>"case_details_link",
  #   "order"=>"desc",
  #   "filter"=>[
  #     "col=docketNumberColumn&val=legacy,evidence_submission",
  #     "col=taskColumn&val=Unaccredited rep,Extension"
  #   ],
  #   "page"=>"3"
  # }>

  def index
    render json: {
      tasks: json_tasks(task_pager.paged_tasks),
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      tasks_per_page: TaskPager::TASKS_PER_PAGE
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def task_pager
    @task_pager ||= TaskPager.new(
      assignee: organization,
      tab_name: params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym],
      page: params[Constants.QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM.to_sym],
      sort_order: params[Constants.QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM.to_sym],
      sort_by: params[Constants.QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM.to_sym],
      filters: params[Constants.QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM.to_sym]
    )
  end

  def json_tasks(tasks)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: organization.ama_task_serializer
    ).call
  end
end
