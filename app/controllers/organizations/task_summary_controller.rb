# frozen_string_literal: true

class Organizations::TaskSummaryController < OrganizationsController
  def index
    redirect_to "/unauthorized" unless organization.users.include?(current_user)

    respond_to do |format|
      format.json do
        render json: {
          members: json_users(organization.users)
        }
      end
    end
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end
end
