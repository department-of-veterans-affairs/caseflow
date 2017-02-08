class Admin::StyleguideController < ApplicationController
  before_action :verify_system_admin
  layout "styleguide"
end
