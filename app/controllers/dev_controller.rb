class DevController < ApplicationController
  def set_user
    session["user"] = User.authentication_service.get_user_session(params[:id])
    redirect_to "/dev/users"
  end

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

    redirect_to "/dev/users"
  end
end
