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

  def raven_extra_context
    { veteran_file_number: veteran_file_number, vbms_id: vbms_id, source: source }
  end

  def ssn
    request.headers["ssn"]
  end

  def source
    request.headers["source"]
  end

  def json_appeals
    Rails.cache.fetch("appeals/v2/#{ssn}", expires_in: 20.hours, force: reload?) do
      Api::V2::Appeals.new(veteran_file_number: veteran_file_number, vbms_id: vbms_id).to_hash
    end
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
