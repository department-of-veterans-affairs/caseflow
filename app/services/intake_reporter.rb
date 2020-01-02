# frozen_string_literal: true

# Summarize the completion time and request issue categories for a range of Decision Review Intakes

class IntakeReporter
  def initialize(type:, start_date: Constants::DATES["AMA_ACTIVATION"].to_date, end_date: Time.zone.today)
    @start_date = start_date
    @end_date = end_date
    @type = type
  end

  def summary
    summary = {
      rating_issue: 0,
      rating_decision: 0,
      nonrating: 0,
      decision_issue: 0,
      unidentified: 0,
      ineligible: 0
    }
    establishment_durations = []
    intakes.each do |intake|
      establishment_durations << (intake.completed_at - intake.started_at).to_i

      appeal = intake.detail
      next unless appeal

      summary[:rating_issue] += appeal.request_issues.rating_issue.count
      summary[:rating_decision] += appeal.request_issues.rating_decision.count
      summary[:nonrating] += appeal.request_issues.nonrating.count
      summary[:decision_issue] += appeal.request_issues.decision_issue.count
      summary[:unidentified] += appeal.request_issues.unidentified.count
      summary[:ineligible] += appeal.request_issues.ineligible.count
    end
    summary[:median_establishment_time] = median(establishment_durations)
    summary
  end

  private

  attr_reader :type, :start_date, :end_date

  def intakes
    Intake.success.where(detail_type: type).where("started_at > ?", start_date).where("started_at <= ?", end_date)
  end

  def median(times)
    return 0 if times.empty?

    len = times.length
    (times[(len - 1) / 2] + times[len / 2]) / 2.0
  end
end
  
