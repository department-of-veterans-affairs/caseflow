class Api::V1::AppealsController < Api::V1::ApplicationController
  before_action :verify_feature_enabled

  rescue_from Caseflow::Error::InvalidSSN, with: :invalid_ssn

  def index
    render json: appeals, each_serializer: ::V1::AppealSerializer, include: "scheduled_hearings"
  end

  private

  def ssn
    request.headers["ssn"]
  end

  def appeals
    @appeals ||= Appeal.for_api(appellant_ssn: ssn)
  end

  def verify_feature_enabled
    not_found unless FeatureToggle.enabled?(:appeals_status)
  end

  def invalid_ssn
    render json: {
      "errors": [
        "status": "422",
        "title": "Invalid SSN",
        "detail": "Please enter a valid 9 digit SSN in the 'ssn' header"
      ]
    }, status: 422
  end
end
