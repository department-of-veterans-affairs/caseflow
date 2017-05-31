class Api::V1::AppealsController < Api::V1::ApplicationController
  before_action :verify_feature_enabled

  rescue_from Caseflow::Error::InvalidSSN, with: :invalid_ssn

  def index
    render json: json_appeals
  rescue ActiveRecord::RecordNotFound
    veteran_not_found
  end

  private

  def ssn
    request.headers["ssn"]
  end

  def json_appeals
    Rails.cache.fetch("appeals/v1/#{ssn}", expires_in: 24.hours, force: reload?) do
      ActiveModelSerializers::SerializableResource.new(
        appeals,
        each_serializer: ::V1::AppealSerializer,
        include: "scheduled_hearings"
      ).as_json
    end
  end

  def appeals
    @appeals ||= Appeal.for_api(appellant_ssn: ssn)
  end

  # Cache can't be busted in prod
  def reload?
    !!params[:reload] && !Rails.deploy_env?(:prod)
  end

  def verify_feature_enabled
    unauthorized unless FeatureToggle.enabled?(:appeals_status)
  end

  def veteran_not_found
    render json: {
      "errors": [
        "status": "404",
        "title": "Veteran not found",
        "detail": "A veteran with that SSN was not found in our systems."
      ]
    }, status: 404
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
