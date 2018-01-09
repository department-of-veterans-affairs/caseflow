class QueueController < Queue::ApplicationController
  def index
    respond_to do |format|
      format.html { render(:index) }
    end
  end

  def tasks
    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          name: "QueueController.tasks") do
      render json: {
        tasks: AttorneyQueue.tasks(current_user.css_id, current_user.id)
      }
    end
  end
end
