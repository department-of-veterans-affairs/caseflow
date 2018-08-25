class OrganizationsController < ApplicationController
  before_action :verify_organization_access, except: [:index]
  before_action :verify_role_access, except: [:index]
  before_action :verify_feature_access, except: [:index]
  before_action :set_application

  def index
    render json: {
      organizations: Organization.all.reject { |o| o.type && o.type == "Vso" }.map { |o| { id: o.id, name: o.name } }
    }
  end

  def show
    render "organizations/show"
  end

  def members
    render json: { members: organization.members.map { |m| { id: m.id, css_id: m.css_id, full_name: m.full_name } } }
  end

  private

  def verify_organization_access
    redirect_to "/unauthorized" unless organization && organization.user_has_access?(current_user)
  end

  def verify_role_access
    verify_authorized_roles(organization.role) if organization.role
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
    # Allow the url to be the ID of the row in the table since this will be what is associated with
    # tasks assigned to the organization in the tasks table.
    Organization.find_by(url: organization_url) || Organization.find(organization_url)
  end
  helper_method :organization
end
