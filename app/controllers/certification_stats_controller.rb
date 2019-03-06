# frozen_string_literal: true

require "json"

class CertificationStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    @stats = {
      hourly: 0...24,
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| CertificationStats.offset(time: CertificationStats.now, interval: interval, offset: i) }
  end

  def logo_name
    "Certification"
  end

  private

  def verify_access
    verify_system_admin
  end

  def interval
    @interval ||= CertificationStats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
  helper_method :interval
end
