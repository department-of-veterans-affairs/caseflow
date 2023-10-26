# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::LegacyIssues::VeteransController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  # TODO: investigate roles
  before_action do
    #api_released?(:api_v3_vbms_intake_ama)
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
    @veteran = Veteran.find_by!(participant_id: params[:participant_id])
    @page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
    # Disallow page(0) since page(0) == page(1) in kaminari. This is to avoid confusion.
    (@page == 0) ? @page = 1 : @page ||= 1
    puts "Legacy Issues API"
    # TODO uncomment when DTO mapper/ serializer is finished
    # render_request_issues(Api::V3::LegacyIssues::VbmsLegacyDtoBuilder.new(veteran, page).hash_response) if veteran
  end

  private

  def find_veteran
    begin
      Veteran.find_by!(participant_id: params[:participant_id])
    rescue ActiveRecord::RecordNotFound
      render_errors(
        status: 404,
        code: :veteran_not_found,
        title: "No Veteran found for the given identifier."
      ) && return
    end
  end

  def render_request_issues(request_issues)
    if request_issues[:request_issues].empty?
      render_errors(
        status: 404,
        code: :no_request_issues_found,
        title: "No Request Issues found for the given veteran."
      ) && return
    else
      render json: request_issues.to_json
    end
  end
end
