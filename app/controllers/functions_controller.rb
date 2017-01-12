require "wannabe_bool"

class FunctionsController < ApplicationController
  before_action :verify_access

  def index
    @functions = current_user.functions
  end

  def change
    current_user.toggle_admin_roles(role: params[:function], enable: params[:enable].to_b)
    redirect_to "/functions"
  end

  private

  def verify_access
    verify_authorized_roles("System Admin")
  end
end
