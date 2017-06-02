class Hearings::WorksheetsController < HearingsController
  def update
    worksheet.update!(worksheet_params)
    render json: { worksheet: worksheet.to_hash }
  end

  private

  def worksheet
    @worksheet ||= hearing
  end

  def worksheet_params
    params.require(:worksheet).permit(:worksheet_witness, :worksheet_contentions, :worksheet_evidence,
                                      :worksheet_coments_for_attorney, :worksheet_military_service,
                                      issues_attributes: [
                                        :id, :hearing_worksheet_status,
                                        :hearing_worksheet_reopen, :hearing_worksheet_vha
                                      ])
  end
end
