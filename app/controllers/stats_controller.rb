require "json"

class StatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def show
    @stats = {
      hourly: 0...24,
      daily: 0...30,
      weekly: 0...26,
      monthly: 0...24
    }[interval].map { |i| Stats.offset(time: Stats.now, interval: interval, offset: i) }
  end

  private

  def verify_access
    verify_authorized_roles("System Admin")
  end

  def json
    @stats.map { |d| { key: d.range_start.to_f, value: d.values } }.to_json
  end
  helper_method :json

  def interval
    @interval ||= Stats::INTERVALS.find { |i| i.to_s == params[:interval] } || :hourly
  end
  helper_method :interval

  # Should be pulled into Caseflow Commons:

  def format_time_duration_stat(seconds)
    return "?? <span class=\"cf-stat-unit\">sec</span>".html_safe unless seconds
    return "#{format('%.2f', seconds)} <span class=\"cf-stat-unit\">sec</span>".html_safe if seconds < 60
    "#{format('%.2f', seconds / 60)} <span class=\"cf-stat-unit\">min</span>".html_safe
  end
  helper_method :format_time_duration_stat

  def format_rate_stat(num, denom)
    "#{@stats[0].values[denom] == 0 ? '??' : (@stats[0].values[num] / @stats[0].values[denom] * 100).round} " \
      "<span class=\"cf-stat-unit\">%</span>".html_safe
  end
  helper_method :format_rate_stat
end
