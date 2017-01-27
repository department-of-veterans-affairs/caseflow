class Test::SetupController < ApplicationController
  before_action :require_uat_test_user, only: [:setup_certification]
  before_action :require_demo, only: [:set_user]

  # Used for resetting data in UAT for certification
  def certification
    test_appeal_id = ENV["TEST_APPEAL_ID"]

    @certification = Certification.find_by(vacols_id: test_appeal_id)
    @certification.uncertify!(current_user.css_id)
    Certification.delete_all(vacols_id: test_appeal_id)

    redirect_to new_certification_path(vacols_id: test_appeal_id)
  end

  # Set current user in DEMO
  def set_user
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

  private

  def require_uat_test_user
    redirect_to "/unauthorized" unless Rails.deploy_env?(:uat) && current_user.css_id == ENV["TEST_USER_ID"]
  end

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end
end
