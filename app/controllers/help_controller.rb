# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :verify_authentication

  def feature_toggle_ui_hash
    {
      otherOrgFeatureThingy: FeatureToggle.enabled?(:otherOrgFeatureThingy, user: current_user)
    }
  end
  helper_method :feature_toggle_ui_hash

  def user_organizations

  end

end
