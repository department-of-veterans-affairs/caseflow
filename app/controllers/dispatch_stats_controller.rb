# frozen_string_literal: true

require "json"

class DispatchStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    # deprecated 2019/08/28
    # either remove this controller entirely or render 404.
    render "errors/404", layout: "application", status: :not_found

    @stats = {
      hourly: 0...24,
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| DispatchStats.offset(time: DispatchStats.now, interval: interval, offset: i) }
  end

  def logo_name
    "Dispatch"
  end

  def interval
    @interval ||= DispatchStats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
  helper_method :interval

  private

  def verify_access
    verify_authorized_roles("Manage Claim Establishment")
  end
end
