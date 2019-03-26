# frozen_string_literal: true

require_relative "../exceptions/bgs_sync_error"

# This job syncs an EndProductEstablishment (end product manager) with up to date BGS and VBMS data
class EndProductSyncJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(end_product_establishment_id)
    RequestStore.store[:current_user] = User.system_user

    begin
      EndProductEstablishment.find(end_product_establishment_id).sync!
    rescue ::TransientBGSSyncError => err
      # we don't care about transient errors in Sentry since it will alert us. we'll just try again later.
      Rails.logger.error err
    rescue StandardError => err
      Raven.capture_exception(err, extra: { end_product_establishment_id: end_product_establishment_id })
    end
  end
end
