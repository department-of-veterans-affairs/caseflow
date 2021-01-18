# frozen_string_literal: true

class WarmVeteranAttrCachesJob < CaseflowJob
    queue_with_priority :low_priority

    def perform
      RequestStore.store[:current_user] = User.system_user
      RequestStore.store[:application] = "queue"



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