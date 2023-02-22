# frozen_string_literal: true

# This job syncs an EndProductEstablishment (end product manager) with up to date BGS and VBMS data
class EndProductSyncJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(end_product_establishment_id)
    RequestStore.store[:current_user] = User.system_user

    begin
      EndProductEstablishment.find(end_product_establishment_id).sync!
    rescue StandardError => error
      capture_exception(error: error, extra: { end_product_establishment_id: end_product_establishment_id })
    end
  end
end
