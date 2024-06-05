# frozen_string_literal: true

require "rake"

class Test::CorrespondenceController < ApplicationController
  before_action :verify_access, only: [:index]

  def index
    return render_access_error unless access_allowed?
    # More code to come
  end


  private

  def verify_access
    current_user.admin? || current_user.inbound_ops_team_supervisor? || bva?
  end

  def bva?
    Bva.singleton.user_has_access?(current_user) ||
      BvaIntake.singleton.user_has_access?(current_user) ||
      BvaDispatch.singleton.user_has_access?(current_user)
  end

  def access_allowed?
    Rails.env.demo? ||
    Rails.env.production?
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end

end
