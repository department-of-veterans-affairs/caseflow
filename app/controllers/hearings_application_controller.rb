# frozen_string_literal: true

class HearingsApplicationController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :react_routed, :check_hearings_out_of_service
  before_action :verify_build_hearing_schedule_access, only: [:build_schedule_index]
  before_action :verify_access_to_reader_or_hearings, only: [:hearing_details_index]
  before_action :verify_view_hearing_schedule_access, only: [:index]

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

  def check_hearings_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearings_out_of_service")
  end
end
