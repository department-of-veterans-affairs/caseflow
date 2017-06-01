class HearingsController < ApplicationController
  # :nocov:
  before_action :verify_access, :set_application

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

  private

  def hearing
    @hearing ||= Hearing.find(hearing_id)
  end

  def hearing_id
    params[:id]
  end

  def verify_access
    verify_authorized_roles("Hearings")
  end

  def set_application
    RequestStore.store[:application] = "hearings"
  end
  # :nocov:
end
