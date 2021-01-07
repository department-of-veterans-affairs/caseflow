# frozen_string_literal: true

class WarmVeteranAttrCachesJob < CaseflowJob
    queue_with_priority :low_priority

    def perform
      RequestStore.store[:current_user] = User.system_user
      RequestStore.store[:application] = "queue"

      warm_veteran_attr_caches_for_ready_ama_appeals
      warm_veteran_for_appeals_distributed_today

      datadog_report_runtime(metric_group_name: "warm_veteran_attr_caches_job")
    end



    private

  def warning_msgs
    @warning_msgs ||= []
  end

  LIMITS = {
    MOST_RECENT: 500,
    OLDEST_CACHED: 1_000
  }.freeze


end