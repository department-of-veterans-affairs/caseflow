# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::AmaIssues::VeteransController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  # TODO: investigate roles
  before_action do
    #FeatureToggle.enabled?(:api_v3_ama_issues)
    #api_released?(:api_v3_ama_issues)
  end

  def show
    veteran = find_veteran
    page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
    # Disallow page(0) since page(0) == page(1) in kaminari. This is to avoid confusion.
    (page == 0) ? page = 1 : page ||= 1
    render_request_issues(Api::V3::AmaIssues::VbmsAmaDtoBuilder.new(veteran, page).hash_response) if veteran
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
