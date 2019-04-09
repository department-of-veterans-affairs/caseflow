# frozen_string_literal: true

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
      all_reviews_and_appeals
    end
  end

  def legacy_appeals
    # Appeals API is currently limited to VBA appeals
    @legacy_appeals ||= AppealHistory.for_api(vbms_id: vbms_id).select do |series|
      series.aoj == :vba
    end
  end

  def hlrs
    @hlrs ||= HigherLevelReview.where(veteran_file_number: veteran_file_number).select { |hlr| hlr.request_issues.any? }
  end

  def supplemental_claims
    # Filter out remanded SC because status and information of those are display through
    # the original HLR or Appeal
    @supplemental_claims ||= SupplementalClaim.where(veteran_file_number: veteran_file_number)
      .where(decision_review_remanded: nil)
      .select { |sc| sc.request_issues.any? }
  end

  def appeals
    @appeals ||= Appeal.where(veteran_file_number: veteran_file_number).select { |a| a.request_issues.any? }
  end

  def all_reviews_and_appeals
    hlr_json = ::V2::HLRStatusSerializer.new(hlrs, is_collection: true).serializable_hash
    sc_json = ::V2::SCStatusSerializer.new(supplemental_claims, is_collection: true).serializable_hash
    appeal_json = ::V2::AppealStatusSerializer.new(appeals, is_collection: true).serializable_hash
    legacy_appeal_json = ::V2::LegacyAppealStatusSerializer.new(legacy_appeals, is_collection: true).serializable_hash

    { data: hlr_json[:data] + sc_json[:data] + appeal_json[:data] + legacy_appeal_json[:data] }
  end

  def vbms_id
    @vbms_id ||= LegacyAppeal.convert_file_number_to_vacols(veteran_file_number)
  end

  def veteran_file_number
    @veteran_file_number ||= fetch_veteran_file_number
  end

  def fetch_veteran_file_number
    fail Caseflow::Error::InvalidSSN if !ssn || ssn.length != 9 || ssn.scan(/\D/).any?

    file_number = BGSService.new.fetch_file_number_by_ssn(ssn)
    fail ActiveRecord::RecordNotFound unless file_number

    file_number
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
end
