class Idt::Api::V1::JudgesController < Idt::Api::V1::BaseController
  before_action :verify_attorney_user

  def index
    render json: { Judge.list_all_with_name_and_id }
  end
end
