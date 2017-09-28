class IntakeController < ApplicationController
  before_action :verify_access, :react_routed
  
  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Intake")
  end

  def index
    respond_to do |format|
      format.html { render(:index) }
    end
  end
end
