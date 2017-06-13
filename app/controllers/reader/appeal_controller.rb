class Reader::AppealController < ApplicationController
  def index
    respond_to do |format|
      format.html { return render(:index) }
      format.json do
        MetricsService.record "Get assignments for #{current_user.vacols_id}" do
          render json: {
            cases: current_user.current_case_assignments
          }
        end
      end
    end
  end
end