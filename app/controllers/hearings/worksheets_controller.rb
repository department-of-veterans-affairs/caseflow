class Hearings::WorksheetsController < HearingsController
  def show
    @hearing_page_title = "Daily Docket | Hearing Worksheet"

    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json do
        render json: hearing_worksheet(params[:id])
      end
    end
  end

  # Until the frontend makes a PUT request, code coverage is at risk, so...
  # def update
  #  worksheet.update!(worksheet_params)
  #  render json: { worksheet: worksheet.to_hash }
  # end

  private

  # Until the frontend makes a PUT request, code coverage is at risk, so...
  # def worksheet
  #  @worksheet ||= hearing
  # end

  # Until the frontend makes a PUT request, code coverage is at risk, so...
  # def worksheet_params
  #  params.require(:worksheet).permit(:worksheet_witness, :worksheet_contentions, :worksheet_evidence,
  #                                    :worksheet_coments_for_attorney, :worksheet_military_service,
  #                                    issues_attributes: [
  #                                      :id, :hearing_worksheet_status,
  #                                      :hearing_worksheet_reopen, :hearing_worksheet_vha
  #                                    ])
  # end

  def hearing_worksheet(_vbms_id) # rubocop:disable Metrics/MethodLength
    # Appeal.where(vmbs_id: _vbms_id)??? TBD
    # possible API
    {
      veteran: {},
      appeal: {},
      streams: {
        appeal_0: {
          issues: {
            issue_0: {
              id: "issue_0",
              program: "Compensation",
              issue: "Service connection",
              levels: "All Others, 5010 - Arthritis, due to trauma",
              description: "Left Elbow",
              reopen: true,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: false
            },
            issue_1: {
              id: "issue_1",
              program: "Compensation",
              issue: "Service connection",
              levels: "All Others, 5010 - Migrane",
              description: "Frequent headaches, caused by concussion",
              reopen: false,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: true
            }
          },
          nod: 99,
          soc: 10,
          docs_in_efolder: 88,
          contentions: "This is a contentions comment",
          periods: "This is a periods comment"
        }
      }
    }
  end
end
