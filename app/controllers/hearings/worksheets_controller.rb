class Hearings::WorksheetsController < HearingsController
  def show
    HearingView.find_or_create_by(hearing_id: params[:hearing_id], user_id: current_user.id).touch

    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json do
        render json: hearing_worksheet
      end
    end
  end

  def show_print
    show
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
                                       :comments_for_attorney,
                                       :prepped)
  end

  def worksheet
    Hearing.find(params[:hearing_id])
  end
  helper_method :worksheet

  def hearing_worksheet
    worksheet.to_hash_for_worksheet(current_user.id)
  end
end
