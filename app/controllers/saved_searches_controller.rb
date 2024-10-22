# frozen_string_literal: true

class SavedSearchesController < ApplicationController
  include ValidationConcern

  before_action :react_routed, :verify_vha_admin

  PERMITTED_PARAMS = [
    :name,
    :description,
    saved_search: {}
  ].freeze

  def index
    searches = SavedSearch.all_saved_searches
    my_search = SavedSearch.my_saved_searches(current_user)
    respond_to do |format|
      format.html { render "index" }
      format.json do
        render json:
         { all_searches: SavedSearchSerializer.new(searches).serializable_hash[:data],
           user_searches: SavedSearchSerializer.new(my_search).serializable_hash[:data] }
      end
    end
  end

  def show
    search = SavedSearch.find_by_id(params[:id])
    respond_to do |format|
      format.html { render "show" }
      format.json { render json: SavedSearchSerializer.new(search).serializable_hash[:data] }
    end
  end

  def create
    @search = current_user.saved_searches.new(save_search_create_params)

    return render json: { message: "Search has been successfully created" }, status: :created if @search.save

    render json:  { message: "Error creating save search" }, status: :unprocessable_entity
  end

  def destroy
    @search = current_user.saved_searches.find(params[:id])
    @search.destroy!
    render json: { status: :ok }
  end

  private

  def save_search_create_params
    params.require(:search).permit(PERMITTED_PARAMS)
  end

  def verify_vha_admin
    return true if current_user.vha_business_line_admin_user?

    redirect_to_unauthorized
  end

  def redirect_to_unauthorized
    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
