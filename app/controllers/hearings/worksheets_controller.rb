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

  # Until the frontend makes a PUT request, code coverage is at risk, so...
  # def update
  #  worksheet.update!(worksheet_params)
  #  render json: { worksheet: worksheet.to_hash }
  # end

  private

  def worksheet
    Hearing.find(params[:hearing_id])
  end
  helper_method :worksheet

  # Until the frontend makes a PUT request, code coverage is at risk, so...
  # def worksheet_params
  #  params.require(:worksheet).permit(:worksheet_witness, :worksheet_contentions, :worksheet_evidence,
  #                                    :worksheet_coments_for_attorney, :worksheet_military_service,
  #                                    issues_attributes: [
  #                                      :id, :hearing_worksheet_status,
  #                                      :hearing_worksheet_reopen, :hearing_worksheet_vha
  #                                    ])
  # end

  def hearing_worksheet # rubocop:disable Metrics/MethodLength
    {
      veteran: {},
      appeal: {},
      streams: {
        "8873": {
          id: 8873,
          issues: {
            "66": {
              id: 66,
              program: "Compensation",
              issue: "Service connection",
              levels: "All Others, 5010 - Arthritis, due to trauma",
              description: "Left Elbow",
              reopen: true,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: false },
            "17": {
              id: 17,
              program: "Compensation",
              issue: "Service connection",
              levels: "All Others, 5010 - Migrane",
              description: "Frequent headaches, caused by concussion",
              reopen: false,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: true }
          },
          nod: 99,
          soc: 10,
          docs_in_efolder: 88 },
        "9092": {
          id: 9092,
          issues: {
            "7654": {
              id: 7654,
              program: "Compensation",
              issue: "Service connection",
              levels: "All Others, 5010 - Arthritis, due to trauma",
              description: "Right Leg",
              reopen: false,
              remand: true,
              allow: false,
              dismiss: false,
              deny: false,
              vha: false },
            "1754": {
              id: 1754,
              program: "Compensation",
              issue: "Service connection",
              levels: "All Others, 4664 - Lyphatic system disability",
              description: "Needs additional examination",
              reopen: false,
              remand: true,
              allow: false,
              dismiss: false,
              deny: true,
              vha: true }
          },
          nod: 99,
          soc: 10,
          docs_in_efolder: 88 } }
    }.merge(worksheet.to_hash_with_appeals_and_issues)
  end
end
