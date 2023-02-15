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

  # This method creates a new EndProductEstablishment and enqueues a job to sync it with BGS and VBMS data
  def establish_new_endproduct_establishment(veteran_file_number, claim_id)
  # Create the new EndProductEstablishment
  new_endproduct = EndProductEstablishment.create!(
    veteran_file_number: veteran_file_number,
    claim_id: claim_id
  )

  # Enqueue a job to sync the new EndProductEstablishment with BGS and VBMS data
  EndProductSyncJob.perform_later(new_endproduct.id)
  new_endproduct
end
