# frozen_string_literal: true

class OrganizationsController < ApplicationController
  before_action :verify_organization_access
  before_action :verify_role_access
  before_action :verify_business_line, only: [:show]
  # Needs to be run after verify_organization_access to ensure the user has access to the VSO in BGS
  before_action :add_user_to_vso, only: [:show]
  before_action :set_application
  skip_before_action :deny_vso_access

  def show
    render "queue/index"
  end

  private

  def verify_organization_access
    redirect_to "/unauthorized" unless organization&.user_has_access?(current_user)
  end

  def verify_business_line
    redirect_to "/decision_reviews/#{organization.url}" if organization.is_a?(::BusinessLine)
  end

  def verify_role_access
    verify_authorized_roles(organization.role) if organization.role
  end

  # VSO staff often visit Caseflow for the first time by visiting a link to their organization's team queue provided
  # by somebody else in the organization or a member of the Caseflow team. Before they visit Caseflow they do not have
  # a User record so they cannot be added as a member of the organization. This function exists to automatically add
  # them to the organization when they visit the organization's team queue.
  def add_user_to_vso
    return if current_user.roles.exclude?("VSO") || organization.users.include?(current_user)

    organization.add_user(current_user)
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def organization_url
    params[:url]
  end

  def organization
    # Allow the url to be the ID of the row in the table since this will be what is associated with
    # tasks assigned to the organization in the tasks table.
    Organization.find_by(url: organization_url) || Organization.find(organization_url)
  end
  helper_method :organization
end
