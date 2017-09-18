class StatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def verify_access
    verify_system_admin
  end
end
