# frozen_string_literal: true

class Test::HearingsController < ApplicationController
  before_action :require_global_admin

  # :nocov:
  def index
    if send_email?
      # TODO: send email
    end

    profile = HearingsProfileHelper.profile_data(current_user)
    render json: profile.merge(email: email_details)
  end

  private

  def require_global_admin
    head :unauthorized unless current_user.global_admin?
  end

  def email_details
    details = { email_sent: "false" }
    if send_email?
      details[:email_sent] = "true"
      details[:email_address] = current_user.email
    end
    details
  end

  def send_email?
    index_params[:send_email]&.casecmp("true")&.zero? && current_user.email.present?
  end

  def index_params
    params.permit(:send_email)
  end
  # :nocov:
end
