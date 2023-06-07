# frozen_string_literal: true

class Metrics::DashboardController < ApplicationController
  skip_before_action :verify_authentication

  def show
    return render_access_error unless access_allowed?

    no_cache

    @metrics = Metric.where('created_at > ?', 1.day.ago).order(created_at: :desc)

    begin
     render :show, layout: "plain_application"
    rescue StandardError => error
      Rails.logger.error(error.full_message)
      raise error.full_message
    end
  end

  private

  def access_allowed?
    current_user.admin? ||
      BoardProductOwners.singleton.user_has_access?(current_user) ||
      CaseflowSupport.singleton.user_has_access?(current_user) ||
      Rails.env.development?
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end
end
