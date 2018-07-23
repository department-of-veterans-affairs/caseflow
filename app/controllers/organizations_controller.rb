class OrganizationsController < ApplicationController
  before_action :verify_organization_access
  before_action :verify_role_access
  before_action :verify_feature_access
  before_action :set_application

  def show
    render "queue/index"
  end

  private

  def verify_organization_access
    redirect_to "/unauthorized" unless organization.user_has_access?(current_user)
  end

  def verify_role_access
    verify_authorized_roles(organization.role)
  end

  def verify_feature_access
    return unless organization.feature

    redirect_to "/unauthorized" unless FeatureToggle.enabled?(organization.feature.to_sym, user: current_user)
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def organization_url
    params[:url]
  end

  def organization
    Organization.find_by(url: organization_url)
  end
end
