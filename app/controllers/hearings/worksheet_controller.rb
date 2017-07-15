class Hearings::WorksheetController < HearingsController

  # TODO: remove this line once application_alt and application merge
  layout "application_alt"

  def show
    @hearing_page_title = "Daily Docket | Hearing Worksheet"

    respond_to do |format|
      format.html { render template: "hearings/dockets/index" }
      format.json do
        render json: hearing_worksheet(params[:id])
      end
    end
  end

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

  def hearing_worksheet(_vbms_id)
    # Appeal.where(vmbs_id: _vbms_id)??? TBD
    # possible API
    {
      veteran: {},
      appeal: {},
      streams: []
    }
  end
end
