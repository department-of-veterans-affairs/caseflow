# frozen_string_literal: true

require "rake"

class Test::CorrespondenceController < ApplicationController
  before_action :verify_access
  before_action :verify_feature_toggle
  def index
    return render_access_error unless verify_access && access_allowed?
    # More code to come
  end


  private

  def verify_access
    return true if current_user.admin? || current_user.inbound_ops_team_supervisor? || bva?

    redirect_to "/unauthorized"
  end

  def bva?
    Bva.singleton.user_has_access?(current_user) ||
      BvaIntake.singleton.user_has_access?(current_user) ||
      BvaDispatch.singleton.user_has_access?(current_user)
  end

  def access_allowed?
    Rails.deploy_env?(:uat) ||
    Rails.env.production?
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end

  def verify_feature_toggle
    correspondence_queue = FeatureToggle.enabled?(:correspondence_queue)
    correspondence_admin = FeatureToggle.enabled?(:correspondence_admin)
    if !correspondence_queue && verify_access
      redirect_to "/under_construction"
    elsif !correspondence_queue || !verify_access || correspondence_admin
      redirect_to "/unauthorized"
    end
  end
end
