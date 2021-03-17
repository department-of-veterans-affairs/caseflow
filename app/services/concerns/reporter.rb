# frozen_string_literal: true

# Mixin methods for *Reporter classes. Statistics, dates, etc.

module Reporter
  extend ActiveSupport::Concern

  def seconds_to_hms(secs)
    [secs / 3600, secs / 60 % 60, secs % 60].map { |segment| segment.to_s.rjust(2, "0") }.join(":")
  end

  def median(times)
    return 0 if times.empty?

    # This algorithm only works if the array is sorted, and our input isn't reliably sorted:
    times.sort!

    len = times.length
    (times[(len - 1) / 2] + times[len / 2]) / 2.0
  end

  def average(times)
    return 0 if times.empty?

    times.sum.to_f / times.length
  end

  def percent(nominator, denominator)
    ((nominator / denominator.to_f) * 100).round(2)
  end
end
