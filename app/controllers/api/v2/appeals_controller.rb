class Api::V2::AppealsController < Api::ApplicationController
  def index
    api_key.api_views.create(vbms_id: vbms_id, source: source)
    render json: json_appeals
  rescue ActiveRecord::RecordNotFound
    veteran_not_found
  rescue Caseflow::Error::InvalidSSN
    invalid_ssn
  rescue Errno::ETIMEDOUT
    upstream_timeout
  end

  private

  def ssn
    request.headers["ssn"]
  end

  def source
    request.headers["source"]
  end

  def json_appeals
    Rails.cache.fetch("appeals/v2/#{ssn}", expires_in: 20.hours, force: reload?) do
      if appeal_status_v3_enabled?
        all_reviews_and_appeals
      else
        ActiveModelSerializers::SerializableResource.new(
          appeals,
          each_serializer: ::V2::AppealSerializer,
          key_transform: :camel_lower
        ).as_json
      end
    end
  end

  def appeals
    # Appeals API is currently limited to VBA appeals
    @appeals ||= AppealHistory.for_api(vbms_id: vbms_id).select do |series|
      series.aoj == :vba
    end
  end

  def hlrs
    @hlrs ||= HigherLevelReview.where(veteran_file_number: vbms_id.sub("S", ""))
  end

  def supplemental_claims
    @supplemental_claims ||= SupplementalClaim.where(veteran_file_number: vbms_id.sub("S", ""))
  end

  def all_reviews_and_appeals
    hlr_json = ActiveModelSerializers::SerializableResource.new(
      hlrs,
      each_serializer: ::V2::HLRStatusSerializer,
      key_transform: :camel_lower
    ).as_json

    sc_json = ActiveModelSerializers::SerializableResource.new(
      supplemental_claims,
      each_serializer: ::V2::SCStatusSerializer,
      key_transform: :camel_lower
    ).as_json

    { data: hlr_json[:data] + sc_json[:data] }
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
    }, status: :not_found
  end

  def invalid_ssn
    render json: {
      "errors": [
        "status": "422",
        "title": "Invalid SSN",
        "detail": "Please enter a valid 9 digit SSN in the 'ssn' header"
      ]
    }, status: :unprocessable_entity
  end

  def upstream_timeout
    render json: {
      "errors": [
        "status": "504",
        "title": "Gateway Timeout",
        "detail": "Upstream service timed out"
      ]
    }, status: :gateway_timeout
  end

  def appeal_status_v3_enabled?
    FeatureToggle.enabled?(:api_appeal_status_v3)
  end
end
