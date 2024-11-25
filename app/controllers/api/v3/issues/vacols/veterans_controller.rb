# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::Issues::VACOLS::VeteransController < Api::V3::BaseController
  # The max amount of Issues that can be paginated on a single page
  DEFAULT_UPPER_BOUND_PER_PAGE = ENV["REQUEST_ISSUE_DEFAULT_UPPER_BOUND_PER_PAGE"].to_i
  include ApiV3FeatureToggleConcern

  before_action do
    api_released?(:api_v3_vacols_issues)
  end

  before_action :validate_headers, :validate_veteran_presence

  def validate_headers
    render_missing_headers unless file_number
  end

  def validate_veteran_presence
    render_veteran_not_found unless veteran
  end

  def veteran
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

  rescue_from Caseflow::Error::InvalidFileNumber, BGS::ShareError do |error|
    Raven.capture_exception(error, extra: raven_extra_context)
    Rails.logger.error "Unable to find Veteran, please review the entered params: #{error}"

    render_veteran_not_found
  end

  def show
    MetricsService.record("VACOLS: Get VACOLS Issues information for Veteran",
                          name: "Api::V3::Issues::Vacols::VeteransController.show") do
                            page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
                            # per_page uses the default value defined in the DtoBuilder unless a param is given,
                            # but it cannot exceed the upper bound
                            if params[:per_page]&.to_i&.positive?
                              per_page_input = params[:per_page].to_i
                              per_page = [per_page_input, DEFAULT_UPPER_BOUND_PER_PAGE].min
                            end
                            # Disallow page(0) since page(0) == page(1) in kaminari. This is to avoid confusion.
                            (page.nil? || page <= 0) ? page = 1 : page ||= 1

                            render_vacols_issues(Api::V3::Issues::VACOLS::VbmsVacolsDtoBuilder.new(@veteran, page,
                                                                                                   per_page))
                          end
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
