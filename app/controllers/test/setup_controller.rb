class Test::SetupController < ApplicationController
  before_action :require_uat_test_user, only: [:certification, :claims_establishment]
  before_action :require_demo, only: [:set_user]

  # Used for resetting data in UAT for certification
  def certification
    test_appeal_id = ENV["TEST_APPEAL_ID"]

    @certification = Certification.find_by(vacols_id: test_appeal_id)
    @certification.uncertify!(current_user.css_id)
    Certification.delete_all(vacols_id: test_appeal_id)

    redirect_to new_certification_path(vacols_id: test_appeal_id)
  end

  # Used for resetting data in UAT for claims establishment
  def claims_establishment
    # Only prepare test if there are less than 20 EstablishClaim tasks, as additional safeguard
    fail "Too many ClaimsEstablishment tasks" if EstablishClaim.count > 20

    EstablishClaim.delete_all
    TestDataService.prepare_claims_establishment!(vacols_id: full_grant_id, cancel_eps: true, decision_type: "full")
    TestDataService.prepare_claims_establishment!(vacols_id: partial_grant_id, cancel_eps: true)

    CreateEstablishClaimTasksJob.perform_now unless ApplicationController.dependencies_faked?
    redirect_to establish_claims_path
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
    redirect_to "/unauthorized" unless test_user?
  end

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end

  def full_grant_id
    "2500867"
  end

  def partial_grant_id
    "2734975"
  end
end
