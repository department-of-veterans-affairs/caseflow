# frozen_string_literal: true

class Hearings::AppealsController < HearingsController
  include HearingsConcerns::VerifyAccess

  before_action :verify_edit_worksheet_access

  def update
    appeal.update!(appeal_params)
    render json: { appeal: appeal.attributes_for_hearing }

  end

  private

  def appeal
    LegacyAppeal.find(params[:appeal_id])
  end
  helper_method :appeal

  def appeal_params
    params.require(:appeal)
      .permit(worksheet_issues_attributes: [:id, :allow, :deny, :remand, :dismiss,
                                            :reopen, :omo, :description, :notes, :from_vacols,
                                            :disposition, :vacols_sequence_id, :_destroy])
  end
end
