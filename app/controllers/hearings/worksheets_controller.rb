class Hearings::WorksheetsController < HearingsController
  def show
    @hearing_page_title = "Daily Docket | Hearing Worksheet"

    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json do
        render json: hearing_worksheet
      end
    end
  end

  def update
    worksheet.update!(worksheet_params)
    worksheet.class.repository.update_vacols_hearing!(worksheet.vacols_record, worksheet_params)
    render json: { worksheet: hearing_worksheet }
  end

  private

  def worksheet_params
    params.require("worksheet").permit(:representative_name,
                                       :witness,
                                       :contentions,
                                       :military_service,
                                       :evidence,
                                       :comments_for_attorney)
  end

  def worksheet
    Hearing.find(params[:hearing_id])
  end
  helper_method :worksheet

  def hearing_worksheet
    worksheet.to_hash_for_worksheet
  end
end
