# frozen_string_literal: true

# Early morning job that checks if the claimant meets the Advance-On-Docket age criteria.
# If criteria is satisfied, all active appeals associated with claimant will be marked as AOD.
class SetAppealAgeAodJob < CaseflowJob
  include ActionView::Helpers::DateHelper

  def perform
    RequestStore.store[:current_user] = User.system_user

    # We expect there to be only one claimant on an appeal. Any claimant meeting the age criteria will cause AOD.
    appeals = non_aod_active_appeals.joins(claimants: :person).where("people.date_of_birth <= ?", 75.years.ago)

    appeals.update_all(age_aod: true)
    appeals.update_all(updated_at: Time.now.utc)

    log_success
  rescue StandardError => error
    log_error(self.class.name, error)
  end

  protected

  def log_success
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}."
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}")
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

  def non_aod_active_appeals
    Appeal.active.where.not(age_aod: true)
  end
end
