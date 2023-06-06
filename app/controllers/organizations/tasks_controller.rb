# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    render json: {
      organization_name: organization.name,
      type: organization.type,
      id: organization.id,
      is_vso: organization.is_a?(::Representative),
      queue_config: QueueConfig.new(assignee: organization).to_hash,
      user_can_bulk_assign: organization.admins.include?(current_user)
    }
  end

  private

  def organization_url
    params[:organization_url]
  end
end
