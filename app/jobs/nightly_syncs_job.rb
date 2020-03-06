# frozen_string_literal: true

# run once a day, overnight, to synchronize systems

class NightlySyncsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue # arbitrary

  def perform
    RequestStore.store[:current_user] = User.system_user

    sync_vacols_users

    datadog_report_runtime(metric_group_name: "nightly_syncs_job")
  end

  private

  def sync_vacols_users
    user_cache_start = Time.zone.now
    CachedUser.sync_from_vacols
    datadog_report_time_segment(segment: "sync_users_from_vacols", start_time: user_cache_start)
  end
end
