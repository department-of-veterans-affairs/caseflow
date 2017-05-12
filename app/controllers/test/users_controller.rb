class Test::UsersController < ApplicationController
  before_action :require_demo, only: [:set_user, :set_end_products]

  # :nocov:
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

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end
  # :nocov:
end
