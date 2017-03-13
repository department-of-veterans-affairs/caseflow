class DispatchStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def verify_access
    verify_authorized_roles("System Admin")
  end
end
