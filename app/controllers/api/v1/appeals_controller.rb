class Api::V1::AppealsController < Api::ApplicationController
  def index
    api_key.api_views.create(vbms_id: vbms_id)
    render json: json_appeals
  rescue ActiveRecord::RecordNotFound
    veteran_not_found
  rescue Caseflow::Error::InvalidSSN
    invalid_ssn
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
    @appeals ||= LegacyAppeal.for_api(vbms_id: vbms_id)
  end

  def vbms_id
    @vbms_id ||= fetch_vbms_id
  end

  def fetch_vbms_id
    fail Caseflow::Error::InvalidSSN if !ssn || ssn.length != 9 || ssn.scan(/\D/).any?
    LegacyAppeal.vbms_id_for_ssn(ssn)
  end

  # Cache can't be busted in prod
  def reload?
    !!params[:reload] && !Rails.deploy_env?(:prod)
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
