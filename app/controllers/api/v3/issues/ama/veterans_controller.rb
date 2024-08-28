# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::Issues::Ama::VeteransController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  before_action do
    api_released?(:api_v3_ama_issues)
  end

  def show
    MetricsService.record("Retrieving AMA Request Issues for Veteran with participant ID: #{params[:participant_id]}",
                          service: "AMA Request Issue endpoint",
                          name: "VeteransController.show") do
                            veteran = find_veteran
                            page = init_page
                            per_page = init_per
                            if veteran
                              render_request_issues(Api::V3::Issues::Ama::VbmsAmaDtoBuilder.new(veteran, page, per_page)
                                                                                           .hash_response)
                            end
                          end
  end

  private

  def init_page
    page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
    # Disallow page(0) or negative. Page(0) == page(1) in kaminari. This is to avoid confusion.
    if page.nil? || page <= 0
      page = 1
    end
    page
  end

  # :reek:FeatureEnvy
  def init_per
    per = ActiveRecord::Base.sanitize_sql(params[:per_page].to_i) if params[:per_page]
    if per.nil? || per <= 0 || per > RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE
      per = [RequestIssue.default_per_page, RequestIssue::DEFAULT_UPPER_BOUND_PER_PAGE].min
    end
    per
  end

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
    render json: request_issues.to_json
  end
end
