# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :verify_authentication

  def feature_toggle_ui_hash
    {
      otherOrgFeatureThingy: FeatureToggle.enabled?(:otherOrgFeatureThingy, user: current_user)
    }
  end
  helper_method :feature_toggle_ui_hash

  def user_organizations_ui_hash(user = current_user)
    user.organizations.map(&:name)
  end
  helper_method :user_organizations_ui_hash

  def organization_membership_requests_ui_hash(_user = current_user)
    {
      "does not exist": "yet"
    }
  end
  helper_method :organization_membership_requests_ui_hash
end
