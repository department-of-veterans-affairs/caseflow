# frozen_string_literal: true

class Test::HearingsController < ApplicationController
  before_action :require_global_admin

  def index
    if send_email?
      Test::HearingsProfileJob.perform_later(current_user, **config_params)
    end

    profile = HearingsProfileHelper.profile_data(current_user, **config_params)
    render json: profile.merge(email: email_details)
  end

  private

  def require_global_admin
    redirect_to "/unauthorized" unless current_user.global_admin?
  end

  def email_details
    details = { email_sent: false }
    if send_email?
      details[:email_sent] = true
      details[:email_address] = current_user.email
    end
    details
  end

  # transform request params into formats to be passed on to other classes
  def config_params
    return_params = {}

    return_params[:limit] = hearings_count_limit if hearings_count_limit.present?
    return_params[:after] = scheduled_after_time if scheduled_after_time.present?
    return_params
  end

  # don't collect more than {limit} of each kind of hearing
  def hearings_count_limit
    if index_params[:limit].present?
      index_params[:limit].to_i
    end
  end

  # only collect hearings that are scheduled after this time
  def scheduled_after_time
    if index_params[:after_year].present? && index_params[:after_month].present? && index_params[:after_day].present?
      Time.zone.local(index_params[:after_year], index_params[:after_month], index_params[:after_day])
    end
  rescue ArgumentError
    nil
  end

  def send_email?
    index_params[:send_email]&.casecmp("true")&.zero? && current_user.email.present?
  end

  def index_params
    params.permit(:send_email, :limit, :after_year, :after_month, :after_day)
  end
end
