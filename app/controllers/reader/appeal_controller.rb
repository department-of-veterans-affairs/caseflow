class Reader::AppealController < Reader::ApplicationController
  def index
    respond_to do |format|
      format.html do
        return redirect_to "/queue" if can_access_queue?
        render(:index)
      end
      format.json do
        MetricsService.record "Get assignments for #{current_user.id}" do
          render json: {
            cases: current_user.current_case_assignments_with_views
          }
        end
      end
    end
  end

  def find_appeals_by_veteran_id
    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          name: "Reader::AppealController.find_appeals_by_veteran_id") do
      appeals = LegacyAppeal.fetch_appeals_by_file_number(veteran_id)
      hashed_appeals = appeals.map { |appeal| appeal.to_hash(issues: appeal.issues) }
        .reject { |appeal_hash| appeal_hash["issues"].empty? }

      render json: {
        appeals: hashed_appeals
      }
    end
  end

  def show
    vacols_id = params[:id]

    respond_to do |format|
      format.html { redirect_to reader_appeal_documents_path(appeal_id: vacols_id) }
      format.json do
        MetricsService.record("VACOLS: Get appeal information for #{vacols_id}",
                              name: "Reader::AppealController.show") do
          appeal = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(vacols_id)
          render json: {
            appeal: json_appeal(appeal)
          }
        end
      end
    end
  end

  private

  def json_appeal(appeal)
    ActiveModelSerializers::SerializableResource.new(
      appeal,
      serializer: appeal.serializer
    ).as_json
  end

  def veteran_id
    request.headers["HTTP_VETERAN_ID"]
  end
end
