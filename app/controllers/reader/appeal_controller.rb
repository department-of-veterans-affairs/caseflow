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

  def find_appeals_by_vbms_id
    vmbs_id = params[:vmbs_id]

    respond_to do |format|
      format.json do
        MetricsService.record("VACOLS: Get appeal information for #{vmbs_id}",
                              name: "AppealController.find_appeals_by_vbms_id") do
          appeals = Appeal.appeals_by_vbms_id(vacols_id)

          hashed_appeals = {}
          appeals.each do |appeal|
            hashed_appeals << appeals.to_hash(issues: appeal.issues)
          end

          render json: {
            appeals: hashed_appeals
          }
        end
      end
    end
  end

  def show
    vacols_id = params[:id]

    respond_to do |format|
      format.json do
        MetricsService.record("VACOLS: Get appeal information for #{vacols_id}",
                              name: "AppealController.show") do
          appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
          render json: {
            appeal: appeal.to_hash(issues: appeal.issues)
          }
        end
      end
    end
  end
end
