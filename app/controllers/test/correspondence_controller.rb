# frozen_string_literal: true

require "rake"

class Test::CorrespondenceController < ApplicationController
  before_action :verify_access, only: [:index]
  def index

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
end
