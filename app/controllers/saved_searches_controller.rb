# frozen_string_literal: true

class SavedSearchesController < ApplicationController
  before_action :react_routed, :verify_access

  PERMITTED_PARAMS = [
    :name,
    :description,
    saved_search: {}
  ].freeze

  def index
    respond_to do |format|
      format.html { render "index" }
      format.json do
        searches = organization.users.includes(:saved_searches).map(&:saved_searches).flatten
        my_search = SavedSearch.for_user(current_user)
        render json:
         { all_searches: SavedSearchSerializer.new(searches).serializable_hash[:data],
           user_searches: SavedSearchSerializer.new(my_search).serializable_hash[:data] }
      end
    end
  end

  def show
    @search = SavedSearch.find_by_id(params[:id])
    @search_json = SavedSearchSerializer.new(@search).serializable_hash[:data]
    respond_to do |format|
      format.html { render "show" }
      format.json { render json:  @search_json }
    end
  end

  def create
    @search = current_user.saved_searches.new(save_search_create_params)

    return render json: { message: "#{@search.name} has been saved." }, status: :created if @search.save

    render json:  { message: "Error creating save search" }, status: :unprocessable_entity
  end

  def destroy
    begin
      @search = current_user.saved_searches.find(params[:id])
      @search.destroy!
      render json: { message: "You have successfully deleted #{@search.name}" }, status: :ok
    rescue ActiveRecord::RecordNotFound => error
      render json: { error: error.to_s }, status: :not_found
    end
  end

  helper_method :organization

  private

  def organization
    @organization ||= Organization.find_by(url: params[:decision_review_business_line_slug])
  end

  def save_search_create_params
    params.require(:search).permit(PERMITTED_PARAMS)
  end

  def verify_access
    return redirect_to_unauthorized if current_user.vha_employee? && !current_user.vha_business_line_admin_user?
  end

  def redirect_to_unauthorized
    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
