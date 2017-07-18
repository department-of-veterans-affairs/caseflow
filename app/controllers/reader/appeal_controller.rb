class Reader::AppealController < Reader::ApplicationController
  def index
    respond_to do |format|
      format.html { render(:index) }
      format.json do
        MetricsService.record "Get assignments for #{current_user.vacols_id}" do
          render json: {
            cases: current_user.current_case_assignments_with_views
          }
        end
      end
    end
  end

  def show
    vacols_id = params[:id]

    respond_to do |format|
      format.json do
        MetricsService.record "Get appeal information for #{vacols_id}" do
          render json: {
            appeal: Appeal.find_or_create_by_vacols_id(vacols_id).to_hash
          }
        end
      end
    end
  end
end
