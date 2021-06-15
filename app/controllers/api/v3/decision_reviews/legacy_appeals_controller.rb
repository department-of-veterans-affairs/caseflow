# frozen_string_literal: true

class Api::V3::DecisionReviews::LegacyAppealsController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  SSN_REGEX = /^\d{9}$/.freeze

  before_action only: [:index] do
    api_released?(:api_v3_legacy_appeals)
  end

  before_action :validate_headers, :validate_veteran_ssn, :validate_veteran_presence

  def index
    render json: serialized_legacy_appeals
  end

  private

  def validate_headers
    render_missing_headers unless veteran_ssn || file_number
  end

  def validate_veteran_ssn
    return unless veteran_ssn

    render_invalid_veteran_ssn unless veteran_ssn.match?(SSN_REGEX)
  end

  def validate_veteran_presence
    render_veteran_not_found unless veteran
  end

  def veteran
    ssn_or_file_number = veteran_ssn || file_number
    @veteran ||= Veteran.find_by_file_number_or_ssn(ssn_or_file_number)
  end

  def veteran_ssn
    @veteran_ssn ||= request.headers["X-VA-SSN"].presence
  end

  def file_number
    @file_number ||= request.headers["X-VA-FILE-NUMBER"].presence
  end

  def render_invalid_veteran_ssn
    render_errors(
      status: 422,
      code: :invalid_veteran_ssn,
      title: "Invalid Veteran SSN",
      detail: "SSN regex: #{SSN_REGEX.inspect})."
    )
  end

  def render_veteran_not_found
    render_errors(
      status: 404,
      code: :veteran_not_found,
      title: "Veteran Not Found"
    )
  end

  def render_missing_headers
    render_errors(
      status: 422,
      code: :missing_identifying_headers,
      title: "Veteran file number or SSN header is required"
    )
  end

  def veteran_legacy_appeals
    LegacyAppeal.fetch_appeals_by_file_number(veteran.file_number)
  end

  def opt_in_eligible_appeals
    veteran_legacy_appeals.select do |appeal|
      return false unless appeal.soc_date

      appeal.eligible_for_opt_in?(receipt_date: Time.zone.today)
    end
  end

  def serialized_legacy_appeals
    Api::V3::LegacyAppealSerializer.new(opt_in_eligible_appeals, is_collection: true).serializable_hash
  end
end
