class SavedSearchesController < ApplicationController
  include ValidationConcern

  before_action :verify_access

  PERMITTED_PARAMS = {
    :name,
    :description,
    :user_id,
    saved_search: {}
  }

  def index
  end

  def show
  end

  def create
    @search = current_user.saved_searches.new(save_search_create_params)
    return render json:  { message: "Search has been successfully created" }, status: :created if @search.save
    render json:  { message: "Error creating save search" }, status: :unprocessable_entity
  end

  def destroy
    @search = current_user.saved_searches.find(id: params[:id])
    @search.destroy!
    render(json: { status: :no_content })
  end

  private

  def business_line
    @business_line ||= BusinessLine.find_by(url: params[:business_line_slug])
  end

  def save_search_create_params
    params.require(:search).permit(PERMITTED_PARAMS)
  end

  def verify_access
    return false unless business_line
    return true if current_user.admin?
    return true if current_user.can?("Admin Intake")
    return true if business_line.user_has_access?(current_user)

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
    # verify_authorized_roles("Mail Intake", "Admin Intake")
    # return true if business_line.user_has_access?(current_user)
  end
end
