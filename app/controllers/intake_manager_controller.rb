require "json"

class IntakeManagerController < ApplicationController
  before_action :verify_access

  def show

  end

  def logo_name
    "Intake"
  end

  def verify_access
    verify_authorized_roles("Admin Intake")
  end
end
