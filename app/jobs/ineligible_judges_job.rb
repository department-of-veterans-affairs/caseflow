# frozen_string_literal: true

# A scheduled job that caches the list of ineligible judges within Caseflow and Vacols for Case Distribution use.
# This job is ran once a week, with a cache that lasts a week.
class IneligibleJudgesJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_with_priority :low_priority
  application_attr :queue

  def perform
    @start_time ||= Time.zone.now
    case_distribution_ineligible_judges

    log_success(@start_time)
  rescue StandardError => error
    log_error(error)
  end

  private

  # {Grabs both vacols and caseflow ineligible judges then merges into one list with duplicates merged
  # if they have the same CSS_ID/SDOMAINID}
  def case_distribution_ineligible_judges
    Rails.cache.fetch("case_distribution_ineligible_judges", expires_in: 1.week) do
      [*CaseDistributionIneligibleJudges.vacols_judges_with_caseflow_records,
       *CaseDistributionIneligibleJudges.caseflow_judges_with_vacols_records]
        .group_by { |h| h[:sdomainid] || h[:css_id] }
        .flat_map do |k, v|
        next v unless k

        v.reduce(&:merge)
      end
    end
  end

  def log_success(start_time)
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}."
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}", self.class.to_s) # may not need this
  end
end
