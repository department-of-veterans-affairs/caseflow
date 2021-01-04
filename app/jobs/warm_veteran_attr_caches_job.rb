# frozen_string_literal: true

class WarmVeteranAttrCaches < CaseflowJob
    queue_with_priority :low_priority
    application_attr :hearing_schedule

    def perform
      RequestStore.store[:current_user] = User.system_user
      RequestStore.store[:application] = "hearings"

      warm_veteran_cache_for_one_appeal

      datadog_report_runtime(metric_group_name: "warm_veteran_attr_caches")
    end

    private

    def warning_msgs
      @warning_msgs ||= []
    end

    LIMITS = {
      MOST_RECENT: 500,
      OLDEST_CACHED: 1_000
    }.freeze

  def warm_veteran_cache_for_one_appeal(appeal_id)
    appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
    refresh_veteran_attr(appeal)
  end

  def refresh_veteran_attr(appeal)
    veteran = appeal.veteran
    begin
      if veteran&.stale_attributes?
        veteran.update_cached_attributes!
      end
      rescue ActiveRecord::RecordNotFound=> error
      Raven.capture_exception(error)
      # if veteran could not be found. Raise exception and don't return, just ignore.
      rescue Errno::ECONNRESET, Savon::HTTPError
      # no nothing
    end
  end
end