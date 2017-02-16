class EmployeeCountController < ApplicationController
  def update_count
    Rails.cache.write('employee_count', params[:count])
    render json: {}
  end
end