class Idt::Api::V1::UsersController < Idt::Api::V1::BaseController
  before_action :verify_attorney_user

  def index
    render json: { data: user.user_info_for_idt }
  end
end
