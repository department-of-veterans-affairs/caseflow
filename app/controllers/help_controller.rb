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

    user.selectable_organizations&.map { |org| org.slice(:name, :type, :url) }
  end

  def pending_membership_requests(user = current_user)
    return [] unless user

    # Serialize the Membership Requests and extract the attributes
    MembershipRequestSerializer.new(user.membership_requests.includes(:organization, :requestor).assigned,
                                    is_collection: true)
      .serializable_hash[:data]
      .map { |hash| hash[:attributes] }
  end

  def user_logged_in?(user = current_user)
    user&.authenticated? || false
  end

  helper_method :feature_toggle_ui_hash, :user_organizations, :pending_membership_requests, :user_logged_in?
end
