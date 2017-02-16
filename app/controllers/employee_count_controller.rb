class EmployeeCountController < ApplicationController
  before_action :verify_manager_access

  def update_count
    Rails.cache.write("employee_count", params[:count])
    render json: {}
  end

  def verify_manager_access
    verify_authorized_roles("Manage Claim Establishment")
  end
end
