class AppealsController < QueueController
  def list
    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          name: "QueueController.appeals") do
      render json: {
        appeals: veteran_id ? json_appeals(Appeal.fetch_appeals_by_file_number(veteran_id)) : []
      }
    end
  end

  private

  def veteran_id
    request.headers["HTTP_VETERAN_ID"]
  end
end
