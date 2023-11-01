# frozen_string_literal: true

#
# A scheduled job that caches the list of ineligible judges within Caseflow and Vacols for Case Distribution use.
# This job is ran once a week, with a cache that lasts a week.
class IneligibleJudgesJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_with_priority :low_priority
  application_attr :queue

  def perform
    case_distribution_ineligible_judges

    log_success
  rescue StandardError => error
    log_error(self.class.name, error)
  end

  # {Grabs both vacols and caseflow ineligible judges then merges into one list with duplicates merged if they have the same CSS_ID/SDOMAINID}
  def case_distribution_ineligible_judges
    Rails.cache.fetch("case_distribution_ineligible_judges", expires_in: 1.week) do
      [*CaseDistributionIneligibleJudges.ineligible_vacols_judges, *CaseDistributionIneligibleJudges.ineligible_caseflow_judges]
        .group_by { |h| h[:sdomainid] || h[:css_id] }
        .flat_map do |k, v|
        next v unless k

        v.reduce(&:merge).tap { |h| h.delete(:css_id) if h.key?(:sdomainid) }
      end
    end
  end

  def log_success
    start_time ||= Time.zone.now
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}."
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}", self.class.to_s) # may not need this
  end

  def log_error(class_name, err)
    start_time ||= Time.zone.now
    duration = time_ago_in_words(start_time)
    msg = "#{class_name} failed after running for #{duration}. Fatal error: #{err.message}"
    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(msg)
    slack_service.send_notification("[ERROR] #{msg}", self.class.to_s)
  end
end
