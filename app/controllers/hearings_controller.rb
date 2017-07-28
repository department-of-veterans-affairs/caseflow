class HearingsController < ApplicationController
  # :nocov:
  before_action :verify_access

  def update
    hearing.update(update_params)
    render json: {}
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

  def update_params
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :aod,
                                     :transcript_requested)
  end

  def date_from_string(date_string)
    # date should be YYYY-MM-DD
    return nil unless /^\d{4}-\d{1,2}-\d{1,2}$/ =~ date_string

    begin
      date_string.to_date
    rescue ArgumentError
      nil
    end
  end
  # :nocov:
end
