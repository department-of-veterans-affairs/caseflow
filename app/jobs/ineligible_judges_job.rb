# frozen_string_literal: true

class IneligibleJudgesJob < CaseflowJob
  def perform
    case_distribution_ineligible_judges

    log_success
  rescue StandardError => error
    log_error(self.class.name, error)
  end

  # {This only adds both lists into one, but we need it to combine those with a matching CSS_ID/SDOMAINID into one.}
  def self.case_distribution_ineligible_judges
    Rails.cache.fetch("case_distribution_ineligible_judges", expires_in: 1.week) do
      CaseDistributionIneligibleJudges.ineligible_vacols_judges.concat
      CaseDistributionIneligibleJudges.ineligible_caseflow_judges
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

    slack_service.send_notification("[ERROR] #{msg}", self.class.to_s)
  end
end
