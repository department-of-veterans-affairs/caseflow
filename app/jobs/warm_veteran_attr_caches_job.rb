# frozen_string_literal: true

class WarmVeteranAttrCachesJob < CaseflowJob
    queue_with_priority :low_priority

    def perform
      RequestStore.store[:current_user] = User.system_user
      RequestStore.store[:application] = "hearings"

      warm_veteran_for_appeals_distributed_today

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

  def warm_veteran_attr_caches_for_ready_ama_appeals
    appeal_ids = DistributionTask.active.pluck(:appeal_id)
    veteran_loop(appeal_ids)
  end

  def warm_veteran_attr_caches_for_ready_legacy_appeals
    #TODO
  end

  def warm_veteran_for_appeals_distributed_today
    appeal_uuids = DistributedCase.where(docket: Constants::AMA_DOCKETS.keys).where("created_at > ?", 1.day.ago).pluck(:case_id)
    veteran_loop(appeal_uuids)
    appeal_vacols_ids = DistributedCase.where(docket: "legacy").where("created_at > ?", 1.day.ago).pluck(:case_id)
    veteran_loop(appeal_vacols_ids)
  end

  def veteran_loop(appeal_ids)
    appeal_ids.each do |appeal_id|
      warm_veteran_cache_for_one_appeal(appeal_id)
    end
  end

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