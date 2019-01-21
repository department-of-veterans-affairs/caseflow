class Hearings::WorksheetsController < HearingsController
  rescue_from ActiveRecord::RecordNotFound do |e|
    Rails.logger.debug "Worksheets Controller failed: #{e.message}"
    render json: { "errors": ["message": e.message, code: 1000] }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid, Caseflow::Error::VacolsRepositoryError do |e|
    Rails.logger.debug "Worksheets Controller failed: #{e.message}"
    render json: { "errors": ["message": e.message, code: 1001] }, status: :not_found
  end

  def show
    HearingView.find_or_create_by(hearing: hearing, user_id: current_user.id).touch

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
    hearing.update!(worksheet_params)
    if hearing.is_a?(LegacyHearing)
      LegacyHearing.repository.update_vacols_hearing!(hearing.vacols_record, worksheet_params)
    end
    render json: { worksheet: hearing_worksheet }
  end

  private

  def worksheet_params
    params.require("worksheet").permit(:representative_name,
                                       :witness,
                                       :military_service,
                                       :prepped,
                                       :summary,
                                       hearing_issue_notes_attributes: [:id, :allow, :deny, :remand,
                                                                        :dismiss, :reopen, :notes])
  end

  def hearing_worksheet
    hearing.to_hash_for_worksheet(current_user.id)
  end
end
