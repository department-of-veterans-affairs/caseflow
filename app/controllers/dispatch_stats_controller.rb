class DispatchStatsController < ApplicationController
  before_action :verify_access

  def verify_access
    verify_authorized_roles("Manage Claim Establishment")
  end
end
