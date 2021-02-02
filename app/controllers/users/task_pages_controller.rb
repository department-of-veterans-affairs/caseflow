# frozen_string_literal: true

class Users::TaskPagesController < UsersController
  include TaskPaginationConcern

  skip_before_action :deny_vso_access

  # This request:
  # /users/{user.id}/task_pages?
  #   tab=on_hold&
  #   sort_by=case_details_link&
  #   order=desc&
  #   filter[]=col%3Ddocket_type%26val%3Dlegacy&
  #   filter[]=col%3Dtask_action%26val%3Dtranslation&
  #   page=3
  #
  # Will be parsed into these params:
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

  def assignee
    user
  end
end
