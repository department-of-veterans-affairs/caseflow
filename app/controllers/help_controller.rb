# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :verify_authentication

  def feature_toggle_ui_hash
    {
      programOfficeTeamManagement: FeatureToggle.enabled?(:program_office_team_management, user: current_user)
    }
  end
  helper_method :feature_toggle_ui_hash

  # TODO: Add more fields if they are needed?
  def user_organizations(user = current_user)
    user.selectable_organizations.map { |org| org.slice(:name, :url) }
  end
  helper_method :user_organizations

  # TODO: Delete this when the OrganizationMembershipRequest model is implemented
  def temp_org_request_data
    [
      {
        id: 12,
        org_name: "Vha",
        status: "Pending"
      },
      {
        id: 13,
        org_name: "Random Vha program office",
        status: "Pending"
      }
    ]
  end

  def open_organization_membership_requests(_user = current_user)
    # user.organization_membership_requests.assigned.includes(:organizations).map do |org_request|
    #   {
    #     name: org_request.organization.name,
    #     url: org_request.organization.url,
    #     orgType: org_request.organization.type,
    #     orgId: org_request.organization.id
    #   }
    # end
    temp_org_request_data
  end
  helper_method :open_organization_membership_requests
end
