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
  #   "filter"=>["col=docket_type&val=legacy", "col=task_action&val=translation"],
  #   "page"=>"3"
  # }>

  def index
    tasks = TaskPage.new(
      assignee: organization,
      tab_name: params[:tab],
      page: params[:page]
    ).paged_tasks

    render json: {
      tasks: json_tasks(tasks)
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: organization.ama_task_serializer
    ).call
  end
end
