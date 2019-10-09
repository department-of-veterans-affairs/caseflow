# frozen_string_literal: true

require "csv"

class ClaimReviewAsyncStatsReporter
  attr_reader :stats

  def initialize(start_date: Constants::DATES["AMA_ACTIVATION"].to_date, end_date: Time.zone.today)
    @start_date = start_date
    @end_date = end_date
    @stats = build
  end

  # rubocop:disable Metrics/MethodLength
  def as_csv
    CSV.generate do |csv|
      csv << %w[
        type
        total
        in_progress
        cancelled
        processed
        established_within_seven_days
        established_within_seven_days_percent
        median
        avg
        max
        min
      ]
      stats.each do |type, stat|
        csv << [
          type,
          stat[:total],
          stat[:in_progress],
          stat[:canceled],
          stat[:processed],
          stat[:established_within_seven_days],
          stat[:established_within_seven_days_percent],
          seconds_to_hms(stat[:median].to_i),
          seconds_to_hms(stat[:avg].to_i),
          seconds_to_hms(stat[:max].to_i),
          seconds_to_hms(stat[:min].to_i)
        ]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_reader :start_date, :end_date

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def build
    {
      supplemental_claims: {
        total: supplemental_claims.count,
        in_progress: supplemental_claims.processable.count,
        canceled: supplemental_claims.canceled.count,
        processed: supplemental_claims.processed.count,
        established_within_seven_days: established_within_seven_days(supplemental_claims_completion_times),
        established_within_seven_days_percent: percent_established_within_seven_days(
          supplemental_claims_completion_times, supplemental_claims.count
        ),
        median: median_time(supplemental_claims_completion_times),
        avg: avg_time(supplemental_claims_completion_times),
        max: supplemental_claims_completion_times.max,
        min: supplemental_claims_completion_times.min
      },
      higher_level_reviews: {
        total: higher_level_reviews.count,
        in_progress: higher_level_reviews.processable.count,
        canceled: higher_level_reviews.canceled.count,
        processed: higher_level_reviews.processed.count,
        established_within_seven_days: established_within_seven_days(higher_level_reviews_completion_times),
        established_within_seven_days_percent: percent_established_within_seven_days(
          higher_level_reviews_completion_times, higher_level_reviews.count
        ),
        median: median_time(higher_level_reviews_completion_times),
        avg: avg_time(higher_level_reviews_completion_times),
        max: higher_level_reviews_completion_times.max,
        min: higher_level_reviews_completion_times.min
      },
      request_issues_updates: {
        total: request_issues_updates.count,
        in_progress: request_issues_updates.processable.count,
        canceled: request_issues_updates.canceled.count,
        processed: request_issues_updates.processed.count,
        established_within_seven_days: established_within_seven_days(request_issues_updates_completion_times),
        established_within_seven_days_percent: percent_established_within_seven_days(
          request_issues_updates_completion_times, request_issues_updates.count
        ),
        median: median_time(request_issues_updates_completion_times),
        avg: avg_time(request_issues_updates_completion_times),
        max: request_issues_updates_completion_times.max,
        min: request_issues_updates_completion_times.min
      }
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def established_within_seven_days(completion_times)
    completion_times.select { |span| span.fdiv(86_400).to_i < 7 }.count
  end

  def percent_established_within_seven_days(completion_times, total)
    ((established_within_seven_days(completion_times) / total.to_f) * 100).round(2)
  end

  def completion_times(claims)
    claims.reject(&:canceled?).select(&:processed?).map do |claim|
      processed_at = claim[claim.class.processed_at_column]
      submitted_at = claim[claim.class.submitted_at_column]
      processed_at - submitted_at
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
      SupplementalClaim
        .where("establishment_submitted_at >= ? AND establishment_submitted_at <= ?", start_date, end_date)
    end
  end

  def higher_level_reviews
    @higher_level_reviews ||= begin
      HigherLevelReview
        .where("establishment_submitted_at >= ? AND establishment_submitted_at <= ?", start_date, end_date)
    end
  end

  def request_issues_updates
    @request_issues_updates ||= begin
      RequestIssuesUpdate.where("submitted_at >= ? AND submitted_at <= ?", start_date, end_date)
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
