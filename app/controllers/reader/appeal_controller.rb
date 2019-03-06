# frozen_string_literal: true

class Reader::AppealController < Reader::ApplicationController
  def index
    redirect_to "/queue"
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
      appeal
    ).as_json
  end
end
