# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::Issues::Legacy::VeteransController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  # TODO: investigate roles
  before_action do
    api_released?(:api_v3_legacy_issues)
  end

  # before_action :validate_headers :validate_veteran_presence

  # def validate_headers
  #   render_missing_headers unless file_number
  # end

  # def render_missing_headers
  #   render_errors(
  #     status: 422,
  #     code: :missing_identifying_headers,
  #     title: "Veteran file number or SSN header is required"
  #   )
  # end

  # def file_number
  #   @file_number ||= request.headers["X-VA-FILE-NUMBER"].presence
  # end

  rescue_from StandardError do |error|
    # byebug
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
    veteran = find_veteran
    render_veteran_not_found unless veteran
    page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
    # Disallow page(0) since page(0) == page(1) in kaminari. This is to avoid confusion.
    (page.nil? || page <= 0) ? page = 1 : page ||= 1
    render_vacols_issues(Api::V3::Issues::Legacy::VbmsLegacyDtoBuilder.new(veteran, page)) if veteran
  end

  private

  def find_veteran
    # Veteran.find_by!(participant_id: params[:participant_id])
    Veteran.find_by_file_number_or_ssn(params[:file_number])
    # Veteran.find_or_create_by_file_number_or_ssn(params[:file_number]) #may need to use this method to create Veteran if one doesn't exist
  end

  def render_veteran_not_found
    render_errors(
      status: 404,
      code: :veteran_not_found,
      title: "No Veteran found for the given identifier."
    ) && return
  end

  def render_vacols_issues(dto)
    # if dto.vacols_issue_count == 0
    #   render_errors(
    #     status: 202,
    #     code: :no_vacols_issues_found,
    #     title: "No VACOLS Issues found for the given veteran"
    #   ) && return
    # else
      vacols_issues = dto.hash_response
      render json: vacols_issues
    # end
  end
end
