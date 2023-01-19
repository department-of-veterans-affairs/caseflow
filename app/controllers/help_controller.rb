# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :verify_authentication

  def feature_toggle_ui_hash
    {
      vhaProgramOfficeRequests: FeatureToggle.enabled?(:vhaProgramOfficeRequests, user: current_user)
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

  def organization_membership_requests_ui_hash(_user = current_user)
    temp_org_request_data
  end
  helper_method :organization_membership_requests_ui_hash
end
