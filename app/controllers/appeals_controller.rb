class AppealsController < ApplicationController
  def index
    return veteran_id_not_found_error unless veteran_id

    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          name: "QueueController.appeals") do

      begin
        appeals = Appeal.fetch_appeals_by_file_number(veteran_id)
      rescue ActiveRecord::RecordNotFound => err
        raise err unless feature_enabled?(:queue_case_search)
        appeals = []
      end

      render json: {
        appeals: json_appeals(appeals)[:data]
      }
    end
  end

  private

  def veteran_id
    request.headers["HTTP_VETERAN_ID"]
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
