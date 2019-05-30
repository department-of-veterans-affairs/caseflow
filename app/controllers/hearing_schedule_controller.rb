# frozen_string_literal: true

class HearingScheduleController < ApplicationController
  before_action :react_routed, :check_hearings_out_of_service
  before_action :verify_build_hearing_schedule_access, only: [:build_schedule_index]
  before_action :verify_hearings_or_reader_access, only: [:hearing_details_index]
  before_action :verify_edit_hearing_schedule_access, except: [:hearing_details_index, :index, :show, :index_print]
  before_action :verify_view_hearing_schedule_access, only: [:index, :show, :index_print]

  def set_application
    RequestStore.store[:application] = "hearings"
  end

  def hearing_details_index
    render "hearings/index"
  end

  def build_schedule_index
    render "hearings/index"
  end

  def index
    render "hearings/index"
  end

  def verify_build_hearing_schedule_access
    verify_authorized_roles("Build HearSched")
  end

  def verify_edit_hearing_schedule_access
    verify_authorized_roles("Edit HearSched", "Build HearSched")
  end

  def verify_view_hearing_schedule_access
    verify_authorized_roles("Edit HearSched", "Build HearSched", "RO ViewHearSched", "VSO", "Hearing Prep")
  end

  def verify_hearings_or_reader_access
    verify_authorized_roles("Reader", "Hearing Prep", "Edit HearSched", "Build HearSched")
  end

  def check_hearings_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearings_out_of_service")
  end
end
