# frozen_string_literal: true

# Runs the priority sync for cancelled and cleared EPs
class EpPrioritySyncJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  BATCH_SIZE = 50

  def perform(batch_limit = BATCH_SIZE)
    RequestStore.store[:current_user] = User.system_user

    begin
      ep_syncer = WarRoom::ReportLoadEndProductSync.new
      synced_cleared_eps = ep_syncer.run_for_cleared_eps(batch_limit)
      synced_cancelled_eps = ep_syncer.run_for_cancelled_eps(batch_limit)

      Raven.capture_message \
        "EP Priority Sync Job: #{DateTime.now}" \
        "Cancelled EPs Attempted/Synced: #{batch_limit}/#{synced_cancelled_eps}" \
        "Cleared EPs Attempted/Synced: #{batch_limit}/#{synced_cleared_eps}"
    rescue Errno::ETIMEDOUT => error
      # no Raven report. We'll try again later.
      Rails.logger.error error
    rescue StandardError => error
      # BOOM 💥
      capture_exception(error: error)
    end
  end
end
