# frozen_string_literal: true

class Reader::ClaimsFolderSearchesController < Reader::ApplicationController
  protect_from_forgery with: :null_session

  def create
    ClaimsFolderSearch.create(
      user: current_user,
      appeal: appeal,
      query: params[:query]
    )

    render json: {}
  end

  private

  def appeal
    Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end
end
