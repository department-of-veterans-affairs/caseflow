# frozen_string_literal: true

class CorrespondenceTaskPagesController < ApplicationController
  include TaskPaginationConcern

  def index
    render json: correspondence_pagination_json
  end

  def assignee
    if params[:user_id]
      User.find(params[:user_id])
    elsif params[:organization_id]
      Organization.find(params[:organization_id])
    end
  end
end
