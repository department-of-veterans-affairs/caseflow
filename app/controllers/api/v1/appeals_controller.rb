class Api::V1::AppealsController < Api::V1::ApplicationController
  before_action :verify_feature_enabled

  def index
    render json: appeals, each_serializer: ::V1::AppealSerializer
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
end
