# frozen_string_literal: true

class CorrespondenceTaskPagesController < ApplicationController
  include TaskPaginationConcern

  def index
    render json: correspondence_pagination_json
  end

  def assignee
    @assignee ||= find_assignee
  end

  private

  def task_pages_params
    params.permit(:user_id, :organization_id)
  end

  def find_assignee
    if task_pages_params[:user_id]
      User.find(task_pages_params[:user_id])
    elsif task_pages_params[:organization_id]
      Organization.find(task_pages_params[:organization_id])
    end
  end
end
