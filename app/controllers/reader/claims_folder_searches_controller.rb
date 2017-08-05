class Reader::ClaimsFolderSearchesController < Reader::ApplicationController
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
    Appeal.find_or_create_by_vacols_id(params[:appeal_id])
  end
end
