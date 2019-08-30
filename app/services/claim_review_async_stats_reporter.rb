# frozen_string_literal: true

require "csv"

class ClaimReviewAsyncStatsReporter
  attr_reader :stats

  def initialize(start_date: Constants::DATES["AMA_ACTIVATION"].to_date, end_date: Time.zone.today)
    @start_date = start_date
    @end_date = end_date
    @stats = build
  end

  def as_csv
    CSV.generate do |csv|
      csv << %w[type total cancelled processed median avg max min]
      stats.each do |type, stat|
        csv << [
          type,
          stat[:total],
          stat[:canceled],
          stat[:processed],
          seconds_to_hms(stat[:median].to_i),
          seconds_to_hms(stat[:avg].to_i),
          seconds_to_hms(stat[:max].to_i),
          seconds_to_hms(stat[:min].to_i)
        ]
      end
    end
  end

  private

  attr_reader :start_date, :end_date

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def build
    {
      supplemental_claims: {
        total: supplemental_claims.count,
        canceled: supplemental_claims.canceled.count,
        processed: supplemental_claims.processed.count,
        median: median_time(supplemental_claims_completion_times),
        avg: avg_time(supplemental_claims_completion_times),
        max: supplemental_claims_completion_times.max,
        min: supplemental_claims_completion_times.min
      },
      higher_level_reviews: {
        total: higher_level_reviews.count,
        canceled: higher_level_reviews.canceled.count,
        processed: higher_level_reviews.processed.count,
        median: median_time(higher_level_reviews_completion_times),
        avg: avg_time(higher_level_reviews_completion_times),
        max: higher_level_reviews_completion_times.max,
        min: higher_level_reviews_completion_times.min
      },
      request_issues_updates: {
        total: request_issues_updates.count,
        canceled: request_issues_updates.canceled.count,
        processed: request_issues_updates.processed.count,
        median: median_time(request_issues_updates_completion_times),
        avg: avg_time(request_issues_updates_completion_times),
        max: request_issues_updates_completion_times.max,
        min: request_issues_updates_completion_times.min
      }
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def completion_times(claims)
    claims.reject(&:canceled?).map do |claim|
      hash = claim.asyncable_ui_hash
      hash[:processed_at] - hash[:submitted_at]
    end
  end

  def supplemental_claims_completion_times
    @supplemental_claims_completion_times ||= completion_times(supplemental_claims)
  end

  def higher_level_reviews_completion_times
    @higher_level_reviews_completion_times ||= completion_times(higher_level_reviews)
  end

  def request_issues_updates_completion_times
    @request_issues_updates_completion_times ||= completion_times(request_issues_updates)
  end

  def supplemental_claims
    @supplemental_claims ||= begin
      SupplementalClaim.processed_or_canceled
        .where("establishment_submitted_at >= ? AND establishment_submitted_at <= ?", start_date, end_date)
    end
  end

  def higher_level_reviews
    @higher_level_reviews ||= begin
      HigherLevelReview.processed_or_canceled
        .where("establishment_submitted_at >= ? AND establishment_submitted_at <= ?", start_date, end_date)
    end
  end

  def request_issues_updates
    @request_issues_updates ||= begin
      RequestIssuesUpdate.processed_or_canceled.where("submitted_at >= ? AND submitted_at <= ?", start_date, end_date)
    end
  end

  def seconds_to_hms(secs)
    [secs / 3600, secs / 60 % 60, secs % 60].map { |segment| segment.to_s.rjust(2, "0") }.join(":")
  end

  def median_time(times)
    return 0 if times.empty?

    len = times.length
    (times[(len - 1) / 2] + times[len / 2]) / 2.0
  end

  def avg_time(times)
    return 0 if times.empty?

    times.sum.to_f / times.length
  end
end
