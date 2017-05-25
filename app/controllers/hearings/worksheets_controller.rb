class Hearings::WorksheetsController < HearingsController
  def update
    worksheet.update!(worksheet_params)
    render json: { worksheet: worksheet.to_hash }
  end

  private

  def worksheet
    @worksheet ||= hearing.worksheet
  end

  def worksheet_params
    params.require(:worksheet).permit(:witness, :contentions, :evidence,
                                      :coments_for_attorney, :military_service,
                                      hearing_worksheet_issues_attributes: [:id, :issue_id,
                                                                            :status, :reopen, :vha])
  end
end
