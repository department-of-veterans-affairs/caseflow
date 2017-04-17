class Test::SetupController < ApplicationController
  before_action :require_non_prod, only: [:index, :uncertify_appeal, :appeal_location_date_reset, :delete_test_data]

  def index
    @certification_appeal = "UNCERTIFY_ME"
    @dispatch_appeal = "DISPATCH_ME"
  end

  def uncertify_appeal
    test_appeal_id = params["UNCERTIFY_ME"][:vacols_id]
    @certification = Certification.find_by(vacols_id: test_appeal_id)
    Form8.delete_all(vacols_id: test_appeal_id)
    appeal = Appeal.find_by(vacols_id: test_appeal_id)
    AppealRepository.uncertify(appeal) unless appeal.nil?
    Certification.delete_all(vacols_id: test_appeal_id)

    redirect_to new_certification_path(vacols_id: test_appeal_id)
  end

  def appeal_location_date_reset
    test_appeal_id = params["DISPATCH_ME"][:vacols_id]
    decision_type = if params["DISPATCH_ME"][:decision_type] == "Full Grant"
                      :full
                    else
                      :partial
                    end

    # Cancel existing EPs and reset the dates
    cancel_eps = params["DISPATCH_ME"][:cancel_eps] == "Yes" ? true : false
    @dispatch_appeal = Appeal.find_or_create_by_vacols_id(test_appeal_id)
    TestDataService.prepare_claims_establishment!(vacols_id: @dispatch_appeal.vacols_id,
                                                  cancel_eps: cancel_eps,
                                                  decision_type: decision_type)
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

  private

  # :nocov:
  def require_non_prod
    redirect_to "/unauthorized" unless test_user?
  end
  # :nocov"
end
