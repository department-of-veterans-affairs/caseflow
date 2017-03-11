class Test::UsersController < ApplicationController
  def index
    @users = User.all
    render "index"
  end

  # Set current user in DEMO
  def set_user
    User.before_set_user # for testing only

    session["user"] = User.authentication_service.get_user_session(params[:id])
    redirect_to "/test/users"
  end

  # Set end products in DEMO
  # :nocov:
  def set_end_products
    case params[:type]
    when "full"
      BGSService.end_product_data = BGSService.existing_full_grants
    when "partial"
      BGSService.end_product_data = BGSService.existing_partial_grants
    when "none"
      BGSService.end_product_data = BGSService.no_grants
    when "all"
      BGSService.end_product_data = BGSService.all_grants
    end

    redirect_to "/test/users"
  end
  # :nocov:
end
