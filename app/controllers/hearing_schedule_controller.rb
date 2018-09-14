class HearingScheduleController < ApplicationController
  before_action :react_routed, :check_hearing_schedule_out_of_service
  before_action :verify_build_hearing_schedule_access, only: [:build_schedule_index]
  before_action :verify_edit_hearing_schedule_access

  def set_application
    RequestStore.store[:application] = "hearing_schedule"
  end

  def build_schedule_index
    render "hearing_schedule/index"
  end

  def index
    render "hearing_schedule/index"
  end

  def verify_build_hearing_schedule_access
    verify_authorized_roles("Build HearSched")
  end

  def verify_edit_hearing_schedule_access
    verify_authorized_roles("Edit HearSched", "Build HearSched")
  end

  def check_hearing_schedule_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearing_schedule_out_of_service")
  end
end
