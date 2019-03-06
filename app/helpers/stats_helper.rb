# frozen_string_literal: true

module StatsHelper
  def json
    @stats.map { |d| { key: d.range_start.to_f, value: d.values } }.to_json
  end

  def format_rate_stat(num, denom)
    rate_stat = if @stats[0].values[denom] == 0 || !@stats[0].values[num]
                  "??"
                else
                  (@stats[0].values[num] / @stats[0].values[denom] * 100).round
                end
    (rate_stat.to_s + "<span class=\"cf-stat-unit\">%</span>").html_safe
  end

  def format_time_duration_stat(seconds)
    return "?? <span class=\"cf-stat-unit\">sec</span>".html_safe unless seconds
    return "#{format('%.2f', seconds)} <span class=\"cf-stat-unit\">sec</span>".html_safe if seconds < 60
    return "#{format('%.2f', seconds / 60)} <span class=\"cf-stat-unit\">min</span>".html_safe if seconds / 60 < 60
    return "#{format('%.2f', seconds / 360)} <span class=\"cf-stat-unit\">hours</span>".html_safe if seconds / 360 < 24

    "#{format('%.2f', seconds / 360 / 24)} <span class=\"cf-stat-unit\">days</span>".html_safe
  end

  def stats_header
    "&nbsp &#124; &nbsp ".html_safe + "Dashboard"
  end
end
