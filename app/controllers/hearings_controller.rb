class HearingsController < ApplicationController
  # :nocov:
  before_action :verify_access

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

  def date_from(param)
    # date should be YYYY-MM-DD
    return nil unless /^\d{4}-\d{1,2}-\d{1,2}$/ =~ param

    begin
      param.to_date
    rescue ArgumentError
      nil
    end
  end
  # :nocov:
end
