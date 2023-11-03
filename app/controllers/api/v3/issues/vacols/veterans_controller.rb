# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::Issues::Vacols::VeteransController < Api::V3::BaseController
  # include ApiV3FeatureToggleConcern

  # before_action do
  #   api_released?(:api_v3_legacy_issues)
  # end

  before_action :validate_headers, :validate_veteran_presence

  def validate_headers
    render_missing_headers unless file_number
  end

  def validate_veteran_presence
    render_veteran_not_found unless veteran
  end

  def veteran
    vet_file_number = file_number
    @veteran ||= find_veteran
  end

  def render_missing_headers
    render_errors(
      status: 422,
      code: :missing_identifying_headers,
      title: "Veteran file number header is required"
    )
  end

  def file_number
    @file_number ||= request.headers["X-VA-FILE-NUMBER"].presence
  end

  rescue_from StandardError do |error|
    Raven.capture_exception(error, extra: raven_extra_context)

    render json: {
      "errors": [
        "status": "500",
        "title": "Unknown error occured",
        "detail": "Message: There was a server error. "\
                  "Use the error uuid to submit a support ticket: #{Raven.last_event_id}"
      ]
    }, status: :internal_server_error
  end

  def show
    page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
    # Disallow page(0) since page(0) == page(1) in kaminari. This is to avoid confusion.
    (page.nil? || page <= 0) ? page = 1 : page ||= 1
    render_vacols_issues(Api::V3::Issues::Legacy::VbmsLegacyDtoBuilder.new(@veteran, page))
  end

  private

  def find_veteran
    # may need to create Veteran if one doesn't exist in Caseflow but exists in BGS
    Veteran.find_or_create_by_file_number_or_ssn(@file_number)
  end

  def render_veteran_not_found
    render_errors(
      status: 404,
      code: :veteran_not_found,
      title: "No Veteran found for the given identifier."
    ) && return
  end

  def render_vacols_issues(dto)
    vacols_issues = dto.hash_response
    render json: vacols_issues
  end
end
