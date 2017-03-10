class Test::SetupController < ApplicationController
  # before_action :require_uat, only: [:index, :uncertify_appeal, :appeal_location_date_reset, :delete_test_data]
  # before_action :require_demo, only: [:set_user, :set_end_products]

  def index
    @certification_appeal = "UNCERTIFY_ME"
    @dispatch_appeal = "DISPATCH_ME"
  end

  # Used for resetting data in UAT for certification
  def uncertify_appeal
    test_appeal_id = params["UNCERTIFY_ME"][:vacols_id]
    unless certification_ids.include?(test_appeal_id)
      flash[:error] = "#{test_appeal_id} is not uncertifiable!"
      redirect_to action: "index"
      return
    end
    @certification = Certification.find_by(vacols_id: test_appeal_id)
    Form8.delete_all(vacols_id: test_appeal_id)
    appeal = Appeal.find_by(vacols_id: test_appeal_id)
    AppealRepository.uncertify(appeal)
    Certification.delete_all(vacols_id: test_appeal_id)

    redirect_to new_certification_path(vacols_id: test_appeal_id)
  end

  # Used for resetting data in UAT for claims establishment
  def appeal_location_date_reset
    test_appeal_id = params["DISPATCH_ME"][:vacols_id]
    if full_grant_ids.include?(test_appeal_id)
      decision_type = :full
    elsif part_remand_ids.include?(test_appeal_id)
      decision_type = :partial
    else
      flash[:error] = "#{test_appeal_id} is not a testable appeal!"
      redirect_to action: "index"
      return
    end

    # Cancel existing EPs and reset the dates
    cancel_eps = params["DISPATCH_ME"][:cancel_eps] == "Yes" ? true : false
    @dispatch_appeal = Appeal.find_or_create_by_vacols_id(test_appeal_id)
    TestDataService.prepare_claims_establishment!(vacols_id: @dispatch_appeal.vacols_id,
                                                  cancel_eps: cancel_eps,
                                                  decision_type: decision_type)
    TestDataService.reset_outcoding_date(@dispatch_appeal)
    redirect_to establish_claims_path
  end

  def delete_test_data
    TestDataService.delete_test_data
    if Appeal.all.empty?
      flash[:success] = "Data cleared"
    else
      flash[:error] = "Data not cleared"
    end
    redirect_to action: "index"
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

  private

  def require_uat
    redirect_to "/unauthorized" unless test_user?
  end

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end

  def certification_ids
    ENV["TEST_APPEAL_IDS"].split(",")
  end

  def full_grant_ids
    ENV["FULL_GRANT_IDS"].split(",")
  end

  def part_remand_ids
    ENV["PART_REMAND_IDS"].split(",")
  end
end
