class StatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_system_admin
end
