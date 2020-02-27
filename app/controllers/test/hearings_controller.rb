# frozen_string_literal: true

class Test::HearingsController < ApplicationController
  before_action :require_global_admin

  # :nocov:
  # TODO: check on vettext endpoint, output times in same format
  def index
    ama_hearings_details = []
    legacy_hearings_details = []
    Hearing.all.order(:id).each { |hearing| ama_hearings_details << hearing_detail(hearing) }
    LegacyHearing.all.order(:id).each { |hearing| legacy_hearings_details << hearing_detail(hearing) }

    render json: {
      email: email_details,
      profile: profile,
      hearings: {
        hearings: ama_hearings_details,
        legacy_hearings: legacy_hearings_details
      }
    }
  end

  private

  def require_global_admin
    head :unauthorized unless current_user.global_admin?
  end

  def email_details
    details = { email_sent: "false" }
    if index_params[:send_email]&.casecmp("true")&.zero? && current_user.email.present?
      details[:email_sent] = "true"
      details[:email_address] = current_user.email
    end
    details
  end

  def profile
    {
      current_user_css_id: current_user.css_id,
      current_user_timezone: current_user.timezone,
      time_zone_name: Time.zone.name,
      config_time_zone: Rails.configuration.time_zone
    }
  end

  def hearing_detail(hearing)
    {
      id: hearing.id,
      type: hearing.class.name,
      external_id: hearing.external_id,
      created_by_timezone: hearing.created_by&.timezone,
      central_office_time_string: hearing.central_office_time_string,
      scheduled_time_string: hearing.scheduled_time_string,
      scheduled_for: hearing.scheduled_for,
      scheduled_time: hearing.scheduled_time
    }
  end

  def index_params
    params.permit(:send_email)
  end
  # :nocov:
end
