class Hearings::DocketsController < ApplicationController
  before_action :verify_access

  private

  def current_user_dockets
    @current_user_dockets ||= HearingDocket.all_for_judge(current_user)
  end
  helper_method :current_user_dockets

  # TODO(jd): Remove this when we have a unique hearings logo
  def logo_class
    "cf-logo-image-default"
  end

  def logo_name
    "Hearing Prep"
  end

  def logo_path
    hearings_dockets_path
  end

  def verify_access
    verify_authorized_roles("Hearings")
  end
end
