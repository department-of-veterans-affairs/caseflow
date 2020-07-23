# frozen_string_literal: true

# Early morning job that checks if the claimant meets the Advance On Docket age criteria.
# If criteria is satisfied, all associated active appeals will be marked as AOD.
class SetAppealAodReasonJob < CaseflowJob

  def perform
    RequestStore.store[:current_user] = User.system_user

    # Alternative approach uses 2 queries:
    #   cs=Claimant.joins(:person).where("people.date_of_birth <= ?", 75.years.ago).where(decision_review_type: :Appeal)
    #   appeals=Appeal.where(aod_reason: nil).where(id: cs.pluck(:decision_review_id))

    # This query assesses all claimants on an appeal. Any claimant meeting the age criteria will cause AOD.
    # We expect there to be only one claimant on an appeal.
    appeals = nonaod_active_appeals.joins(claimants: :person).where("people.date_of_birth <= ?", 75.years.ago)
    # Double-checking: appeals.map{|a| a.claimant.person.date_of_birth.year }

    # Appeal.active.count.count
    # => 47955
    # appeals.count.count => 3086

    appeals.update_all(aod_reason: :age)
    appeals.update_all(updated_at: Time.now)

    appeals.each{ |a| a.update(aod_reason: :age) }
    # NOT NEEDED: appeals.update_all(aod_reason: Appeal.aod_reasons[:age])

    # TODO: For LegacyAppeal with aod set, update `aod_reason` field.

    log_success
  rescue StandardError => error
    log_error(self.class.name, error)
  ensure
    datadog_report_runtime(metric_group_name: name.underscore)
  end

  protected

  def log_success
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}."
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}") # may not need this
  end

  def log_error(collector_name, err)
    duration = time_ago_in_words(start_time)
    msg = "#{collector_name} failed after running for #{duration}. Fatal error: #{err.message}"
    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err, extra: { stats_collector_name: collector_name })

    slack_service.send_notification("[ERROR] #{msg}")
  end

  private

  def nonaod_active_appeals
    Appeal.active.where(aod_reason: nil)
  end
end
