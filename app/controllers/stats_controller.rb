class StatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def verify_access
    # All folks with system admin role
    # should be able to see the stats page,
    # even if they don't return true for `user.admin?`
    verify_authorized_roles("System Admin")
  end
end
