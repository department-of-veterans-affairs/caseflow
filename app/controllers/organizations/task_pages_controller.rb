# frozen_string_literal: true

class Organizations::TaskPagesController < OrganizationsController
  include TaskPaginationConcern

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
    render json: pagination_json
  end

  private

  def organization_url
    params[:organization_url]
  end

  def assignee
    organization
  end
end
