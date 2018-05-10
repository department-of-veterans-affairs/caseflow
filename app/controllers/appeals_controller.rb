class AppealsController < ApplicationController
  before_action :react_routed

  def index
    return veteran_id_not_found_error unless veteran_id

    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          service: :queue,
                          name: "AppealsController.index") do

      begin
        appeals = LegacyAppeal.fetch_appeals_by_file_number(veteran_id)
      rescue ActiveRecord::RecordNotFound
        appeals = []
      end

      render json: {
        appeals: json_appeals(appeals)[:data]
      }
    end
  end

  def document_count
    render json: { document_count: appeal.number_of_documents }
  end

  def show
    # :nocov:
    no_cache

    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        vacols_id = params[:id]
        MetricsService.record("VACOLS: Get appeal information for VACOLS ID #{vacols_id}",
                              service: :queue,
                              name: "AppealsController.show") do
          appeal = LegacyAppeal.find_or_create_by_vacols_id(vacols_id)
          render json: { appeal: json_appeals([appeal])[:data][0] }
        end
      end
    end
    # :nocov:
  end

  private

  # https://stackoverflow.com/a/748646
  def no_cache
    # :nocov:
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    # :nocov:
  end

  def veteran_id
    request.headers["HTTP_VETERAN_ID"]
  end

  def appeal
    @appeal ||= Appeal.find_or_create_by_vacols_id(params[:appeal_id])
  end

  def veteran_id_not_found_error
    render json: {
      "errors": [
        "title": "Must include Veteran ID",
        "detail": "Veteran ID should be included as HTTP_VETERAN_ID element of request headers"
      ]
    }, status: 400
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
