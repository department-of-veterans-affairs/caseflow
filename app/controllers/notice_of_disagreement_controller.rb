# frozen_string_literal: true

# Controller to allow Notice of Disagreement (NOD) date to be edited

class NoticeOfDisagreementController < AppealsController
  # before_action :verify_access

  def update_nod
    return record_not_found unless appeal
    if params[:nod_date]
      appeal.update!(receipt_date: params[:nod_date])
    else
      render json: { error_code: :no_changes }, status: :unprocessable_entity
    end
  end
  
  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: :not_found
  end

  # def verify_access
  #   verify_authorized_roles("")
  # end
end