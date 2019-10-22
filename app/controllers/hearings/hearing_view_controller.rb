# frozen_string_literal: true

class Hearings::HearingViewController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_edit_worksheet_access

  def create
    HearingView.find_or_create_by(hearing: hearing, user_id: current_user.id).touch

    head :ok
  end

  private

  def hearing
    @hearing ||= Hearing.find_hearing_by_uuid_or_vacols_id(params[:id])
  end
end
