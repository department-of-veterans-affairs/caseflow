# frozen_string_literal: true

# Early morning job that checks if the claimant meets the Advance-On-Docket age criteria.
# If criteria is satisfied, all active appeals associated with claimant will be marked as AOD.
# This job also handles the scenario where a claimant's DOB is updated such that their appeal(s) are no longer AOD.
class SetAppealAgeAodJob < CaseflowJob
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :queue

  def perform
    RequestStore.store[:current_user] = User.system_user

    aod_appeals_to_unset = appeals_to_unset_age_based_aod
    detail_msg = "IDs of appeals to remove age-related AOD: #{aod_appeals_to_unset.pluck(:id)}"
    aod_appeals_to_unset.update_all(aod_based_on_age: false, updated_at: Time.now.utc)

    # We expect there to be only one claimant on an appeal. Any claimant meeting the age criteria will cause AOD.
    appeals_for_aod = appeals_to_set_age_based_aod
    detail_msg += "\nIDs of appeals to be updated with age-related AOD: #{appeals_for_aod.pluck(:id)}"
    appeals_for_aod.update_all(aod_based_on_age: true, updated_at: Time.now.utc)

    log_success(detail_msg)
  rescue StandardError => error
    log_error(self.class.name, error, detail_msg)
  end

  protected

  def log_success(details)
    duration = time_ago_in_words(start_time)
    msg_title = "[INFO] #{self.class.name} completed after running for #{duration}."
    Rails.logger.info("#{msg_title}\n#{details}")

    slack_service.send_notification(details, msg_title)
  end

  def log_error(collector_name, err, details)
    duration = time_ago_in_words(start_time)
    msg_title = "[ERROR] #{collector_name} failed after running for #{duration}. Fatal error: #{err.message}."
    Rails.logger.info("#{msg_title}\n#{details}")
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err, extra: { stats_collector_name: collector_name })

    slack_service.send_notification(details, msg_title)
  end

  private

  def appeals_to_unset_age_based_aod
    active_appeals_with_age_based_aod.joins(claimants: :person).where("people.date_of_birth > ?", 75.years.ago)
  end

  def active_appeals_with_age_based_aod
    Appeal.active.where(aod_based_on_age: true)
  end

  def appeals_to_set_age_based_aod
    active_appeals_without_age_based_aod.joins(claimants: :person).where("people.date_of_birth <= ?", 75.years.ago)
  end

  def active_appeals_without_age_based_aod
    # `aod_based_on_age` is initially nil
    # `aod_based_on_age` being false means that it was once true (in the case where the claimant's DOB was updated)
    Appeal.active.where(aod_based_on_age: [nil, false])
  end
end
