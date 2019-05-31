# frozen_string_literal: true

class Organizations::MembersController < OrganizationsController
  def index
    redirect_to "/unauthorized" unless organization.users.include?(current_user)

    render json: {
      members: organization.users
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end
end