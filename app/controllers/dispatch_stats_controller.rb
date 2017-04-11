require "json"

class DispatchStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    @dispatch_stats = {
      hourly: 0...24,
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| DispatchStats.offset(time: DispatchStats.now, interval: interval, offset: i) }
  end

  private

  def verify_access
    verify_authorized_roles("Manage Claim Establishment")
  end

  def json
    @dispatch_stats.map { |d| { key: d.range_start.to_f, value: d.values } }.to_json
  end
  helper_method :json

  def interval
    @interval ||= DispatchStats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
  helper_method :interval

  def format_rate_stat(num, denom)
    rate_stat = if @dispatch_stats[0].values[denom] == 0 || !@dispatch_stats[0].values[num]
                  "??"
                else
                  (@dispatch_stats[0].values[num] / @dispatch_stats[0].values[denom] * 100).round
                end
    (rate_stat.to_s + "<span class=\"cf-stat-unit\">%</span>").html_safe
  end
  helper_method :format_rate_stat

  def format_time_duration_stat(seconds)
    return "?? <span class=\"cf-stat-unit\">sec</span>".html_safe unless seconds
    return "#{format('%.2f', seconds)} <span class=\"cf-stat-unit\">sec</span>".html_safe if seconds < 60
    "#{format('%.2f', seconds / 60)} <span class=\"cf-stat-unit\">min</span>".html_safe
  end
  helper_method :format_time_duration_stat
end
