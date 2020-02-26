# frozen_string_literal: true

# Summarize the completion time and request issue categories for a range of Decision Review Intakes

class IntakeReporter
  include Reporter

  def initialize(type:, start_date: Constants::DATES["AMA_ACTIVATION"].to_date, end_date: Time.zone.tomorrow)
    @start_date = start_date
    @end_date = end_date
    @type = type
  end

  # rubocop:disable Metrics/AbcSize
  def report
    durations = []
    intakes.each do |intake|
      durations << (intake.completed_at - intake.started_at).to_i

      decision_review = intake.detail
      next unless decision_review

      summary[:rating_issue] += decision_review.request_issues.rating_issue.count
      summary[:rating_decision] += decision_review.request_issues.rating_decision.count
      summary[:nonrating] += decision_review.request_issues.nonrating.count
      summary[:decision_issue] += decision_review.request_issues.decision_issue.count
      summary[:unidentified] += decision_review.request_issues.unidentified.count
      summary[:ineligible] += decision_review.request_issues.ineligible.count
    end
    summary[:median_intake_time] = median(durations)
    summary
  end
  # rubocop:enable Metrics/AbcSize

  private

  attr_reader :type, :start_date, :end_date

  def intakes
    Intake.success.where(detail_type: type).where("started_at > ?", start_date).where("started_at <= ?", end_date)
  end

  def summary
    @summary ||= {
      rating_issue: 0,
      rating_decision: 0,
      nonrating: 0,
      decision_issue: 0,
      unidentified: 0,
      ineligible: 0
    }
  end
end
