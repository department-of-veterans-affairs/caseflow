class SavedSearchesController < ApplicationController
  include ValidationConcern

  before_action :verify_access, :react_routed

  PERMITTED_PARAMS = [
    :name,
    :description,
    saved_search: {}
  ].freeze

  def index
    respond_to do |format|
      format.html { render "index" }
      format.json { render_saved_search_tab }
    end
  end

  def create
    @search = current_user.saved_searches.new(save_search_create_params)
    return render json:  { message: "Search has been successfully created" }, status: :created if @search.save
    render json:  { message: "Error creating save search" }, status: :unprocessable_entity
  end

  def destroy
    @search = current_user.saved_searches.find(params[:id])
    @search.destroy!
    render json: { status: :ok }
  end

  private

  def business_line
    @business_line ||= BusinessLine.find_by(url: params[:business_line_slug])
  end

  def save_search_create_params
    params.require(:search).permit(PERMITTED_PARAMS)
  end

  def allowed_params
    params.permit(
      :business_line_slug,
      :tab
    )
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

  def render_saved_search_tab
    tab_name = allowed_params[:tab]
    searches = case tab_name
               when "my_saved_searches" then SavedSearch.my_saved_searches(current_user)
               when "all_saved_searches" then SavedSearch.all_saved_searches
               when nil
                 return missing_tab_parameter_error
               else
                 return unrecognized_tab_name_error
               end

    render json: SavedSearchSerializer.new(searches)
  end

  def missing_tab_parameter_error
    render json: { error: "'tab' parameter is required." }, status: :bad_request
  end

  def unrecognized_tab_name_error
    render json: { error: "Tab name provided could not be found" }, status: :not_found
  end
end
