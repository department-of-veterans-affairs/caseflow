class Idt::Api::V1::UsersController < Idt::Api::V1::BaseController
  before_action :verify_attorney_user

  def index
  	render json: {}
  end
end
