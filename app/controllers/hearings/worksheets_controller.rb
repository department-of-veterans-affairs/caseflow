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
    render json: { worksheet: hearing_worksheet }
  end

  private

  def worksheet
    Hearing.find(params[:hearing_id])
  end
  helper_method :worksheet

  def worksheet_params
    params.require(:worksheet)
          .permit(worksheet_issues_attributes: [:id, :allow, :deny, :remand, :dismiss,
                                                :reopen, :vha, :program, :name, :from_vacols,
                                                :vacols_sequence_id, :_destroy, description: [],
                                                                                levels: []])
  end

  def hearing_worksheet # rubocop:disable Metrics/MethodLength
    {
      streams: [
        {
          id: 8873,
          worksheet_issues: [
            {
              id: 66,
              program: "Compensation",
              name: "Service connection",
              levels: "All Others, 5010 - Arthritis, due to trauma",
              description: "Left Elbow",
              reopen: true,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: false,
              from_vacols: true },
            {
              id: 17,
              program: "Compensation",
              name: "Service connection",
              levels: "All Others, 5010 - Migrane",
              description: "Frequent headaches, caused by concussion",
              reopen: false,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: true,
              from_vacols: false }
          ]
        },
        {
          id: 9092,
          worksheet_issues: [
            {
              id: 7654,
              program: "Compensation",
              name: "Service connection",
              levels: "All Others, 5010 - Arthritis, due to trauma",
              description: "Right Leg",
              reopen: false,
              remand: true,
              allow: false,
              dismiss: false,
              deny: false,
              vha: false,
              from_vacols: true },
            {
              id: 1754,
              program: "Compensation",
              name: "Service connection",
              levels: "All Others, 4664 - Lyphatic system disability",
              description: "Needs additional examination",
              reopen: false,
              remand: true,
              allow: false,
              dismiss: false,
              deny: true,
              vha: true,
              from_vacols: false }
          ]
        }
      ]
    }.merge(worksheet.to_hash_for_worksheet)
  end
end
