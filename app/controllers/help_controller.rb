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

  def pending_membership_requests(user = current_user)
    # TODO: Might also narrow it down by organization?
    # Could also do this based on user.membership_requests if I make the association. Probably the better way
    MembershipRequest.includes(:user, :organization).where(decider: user).all.map do |membership_request|
      {
        name: membership_request.organization.name,
        url: membership_request.organization.url,
        orgType: membership_request.organization.type,
        orgId: membership_request.organization.id
      }
    end
  end
  helper_method :pending_membership_requests
end
