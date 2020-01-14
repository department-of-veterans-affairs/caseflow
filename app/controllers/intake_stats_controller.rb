# frozen_string_literal: true

require "json"

class IntakeStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    # deprecated 2019/08/28
    render "errors/404", layout: "application", status: :not_found
  end

  private

  def verify_access
    verify_authorized_roles("Admin Intake")
  end
end
