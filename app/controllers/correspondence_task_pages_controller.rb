# frozen_string_literal: true

class CorrespondenceTaskPagesController < ApplicationController
  include TaskPaginationConcern

  def index
    render json: correspondence_pagination_json
  end

  def assignee
    User.find(params[:user_id])
  end
end
