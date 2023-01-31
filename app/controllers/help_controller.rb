# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :verify_authentication

  def feature_toggle_ui_hash(user = current_user)
    {
      programOfficeTeamManagement: FeatureToggle.enabled?(:program_office_team_management, user: user)
    }
  end

  def user_organizations(user = current_user)
    return [] unless user

    user&.selectable_organizations&.map { |org| org.slice(:name, :url) }
  end

  def pending_membership_requests(user = current_user)
    return [] unless user

    user&.membership_requests&.includes(:organization)&.assigned&.map do |membership_request|
      {
        name: membership_request.organization.name,
        url: membership_request.organization.url,
        orgType: membership_request.organization.type,
        orgId: membership_request.organization.id
      }
    end
  end

  helper_method :feature_toggle_ui_hash, :user_organizations, :pending_membership_requests
end
