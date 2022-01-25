# frozen_string_literal: true

class Idt::Api::V2::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  def details
    case_search = request.headers["HTTP_CASE_SEARCH"]

    result = if docket_number?(case_search)
               CaseSearchResultsForDocketNumber.new(
                 docket_number: case_search, user: current_user
               ).call
             else
               CaseSearchResultsForVeteranFileNumber.new(
                 file_number_or_ssn: case_search, user: current_user
               ).call
             end

    render_search_results_as_json(result)
  end

  def reader_appeal
    MetricsService.record("VACOLS: Get appeal information for #{appeal_id}",
                          name: "Reader::AppealController.show") do
      render json: {
        appeal: json_appeal(appeal)
      }
    end
  end

  private

  # :reek:DuplicateMethodCall { allow_calls: ['result.extra'] }
  # :reek:FeatureEnvy
  def render_search_results_as_json(result)
    if result.success?
      render json: result.extra[:search_results]
    else
      render json: result.to_h, status: result.extra[:status]
    end
  end

  # :reek:FeatureEnvy
  def json_appeal(appeal)
    if appeal.is_a?(Appeal)
      WorkQueue::AppealSerializer.new(appeal, params: { user: current_user })
    elsif appeal.is_a?(LegacyAppeal)
      WorkQueue::LegacyAppealSerializer.new(appeal)
    end
  end

  def docket_number?(search)
    !search.nil? && search.match?(/\d{6}-{1}\d+$/)
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
  end
  helper_method :appeal

  def appeal_id
    params[:appeal_id]
  end
end
