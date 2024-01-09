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
    log_judge_list
    log_success(@start_time)
  rescue StandardError => error
    log_error(error)
  end

  private

  # {Grabs both vacols and caseflow ineligible judges then merges into one list with duplicates merged if they have the same CSS_ID/SDOMAINID}
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

  def judges_from_distributions
    <<-SQL
      SELECT "hearings"."judge_id" AS "judge_id"
      FROM "hearings"
      LEFT JOIN "appeals" "Appeals" ON "hearings"."appeal_id" = "Appeals"."id" LEFT JOIN "distributed_cases" "Distributed Cases" ON "Appeals"."veteran_file_number" = "Distributed Cases"."case_id" LEFT JOIN "distributions" "Distributions" ON "Distributed Cases"."distribution_id" = "Distributions"."id"
      WHERE ("Distributions"."completed_at" >= CAST(now() AS date)
        AND "Distributions"."completed_at" < CAST((CAST(now() AS timestamp) + (INTERVAL '1 day')) AS date))
      LIMIT 1048575
    SQL
  end

  def cross_check_ineligible_judge_list
    ineligible_judge_list = Rails.cache.fetch("case_distribution_ineligible_judges")
    ineligible_return_list = []

    ineligible_judge_list.each do |judge|
      judges_from_distributions.include? judge.id ? ineligible_list_return_list.push(judge) : nil
    end
    ineligible_return_list
  end

  def log_judge_list
    msg = "Cross-checked ineligible judge list: #{cross_check_ineligible_judge_list}"
    Rails.logger.info(msg)
  end

  def log_success(start_time)
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}."
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}", self.class.to_s) # may not need this
  end
end
