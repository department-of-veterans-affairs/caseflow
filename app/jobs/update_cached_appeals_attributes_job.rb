# frozen_string_literal: true

VACOLS_BATCH_SIZE = 1_000
POSTGRES_BATCH_SIZE = 10_000

class UpdateCachedAppealsAttributesJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :queue

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = UpdateCachedAppealsAttributesJob.name.underscore

  def perform
    RequestStore.store[:current_user] = User.system_user
    ama_appeals_start = Time.zone.now
    cache_ama_appeals
    datadog_report_time_segment(segment: "cache_ama_appeals", start_time: ama_appeals_start)

    legacy_appeals_start = Time.zone.now
    cache_legacy_appeals
    datadog_report_time_segment(segment: "cache_legacy_appeals", start_time: legacy_appeals_start)

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  rescue StandardError => error
    log_error(@start_time, error)
  else
    log_warning unless warning_msgs.empty?
  end

  def cache_ama_appeals
    appeals = Appeal.includes(:available_hearing_locations)
      .where(id: open_appeals_from_tasks(Appeal.name))
      .order(id: :desc) # cache most created appeals first

    cached_appeals = cached_appeal_service.cache_ama_appeals(appeals)

    increment_appeal_count(cached_appeals.length, Appeal.name)
  end

  def open_appeals_from_tasks(appeal_type)
    Task.open.where(appeal_type: appeal_type).pluck(:appeal_id).uniq
  end

  def cache_legacy_appeals
    # Avoid lazy evaluation bugs by immediately plucking all VACOLS IDs. Lazy evaluation of the LegacyAppeal.find(...)
    # was previously causing this code to insert legacy appeal attributes that corresponded to NULL ID fields.
    legacy_appeals = LegacyAppeal.includes(:available_hearing_locations)
      .where(id: open_appeals_from_tasks(LegacyAppeal.name))
      .order(id: :desc) # cache most created appeals first

    cache_postgres_data_start = Time.zone.now
    cache_legacy_appeal_postgres_data(legacy_appeals)
    datadog_report_time_segment(segment: "cache_legacy_appeal_postgres_data", start_time: cache_postgres_data_start)

    cache_vacols_data_start = Time.zone.now
    cache_legacy_appeal_vacols_data(legacy_appeals)
    datadog_report_time_segment(segment: "cache_legacy_appeal_vacols_data", start_time: cache_vacols_data_start)
  end

  def cache_legacy_appeal_postgres_data(legacy_appeals)
    # this transaction times out so let's try to do this in batches
    legacy_appeals.in_groups_of(POSTGRES_BATCH_SIZE, false) do |batch_legacy_appeals|
      cached_appeals = cached_appeal_service.cache_legacy_appeal_postgres_data(batch_legacy_appeals)

      increment_appeal_count(cached_appeals.length, LegacyAppeal.name)
    end
  end

  def cache_legacy_appeal_vacols_data(legacy_appeals)
    legacy_appeals.in_groups_of(VACOLS_BATCH_SIZE, false).each do |batch_legacy_appeals|
      cached_appeals = cached_appeal_service.cache_legacy_appeal_vacols_data(batch_legacy_appeals)

      increment_vacols_update_count(cached_appeals.count)
    end
  end

  delegate :warning_msgs, to: :cached_appeal_service

  private

  def increment_vacols_update_count(count)
    count.times do
      DataDogService.increment_counter(
        app_name: APP_NAME,
        metric_group: METRIC_GROUP_NAME,
        metric_name: "vacols_cases_cached"
      )
    end
  end

  def increment_appeal_count(count, appeal_type)
    count.times do
      DataDogService.increment_counter(
        app_name: APP_NAME,
        metric_group: METRIC_GROUP_NAME,
        metric_name: "appeals_to_cache",
        attrs: {
          type: appeal_type
        }
      )
    end
  end

  def cached_appeal_service
    @cached_appeal_service ||= CachedAppealService.new
  end

  def log_warning
    slack_msg = warning_msgs.join("\n")
    slack_service.send_notification(slack_msg, "[WARN] UpdateCachedAppealsAttributesJob: first 100 warnings")
  end

  def log_error(start_time, err)
    duration = time_ago_in_words(start_time)
    msg = "UpdateCachedAppealsAttributesJob failed after running for #{duration}. Fatal error: #{err.message}"

    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err)

    slack_msg = "See Sentry event #{Raven.last_event_id}"
    slack_service.send_notification(slack_msg,
                                    "[ERROR] UpdateCachedAppealsAttributesJob failed after running for #{duration}.")

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end
end
