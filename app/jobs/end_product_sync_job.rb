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

  # This method creates a new EndProductEstablishment and enqueues a job to sync it with BGS and VBMS data for
  # supplimental claims with dupplicateEP status containing Can or Cleared
  def establish_new_endproduct_establishment(veteran_file_number, claim_id)
    RequestStore.store[:current_user] = User.system_user
  # Create the new EndProductEstablishment for dupplicate supp claims Can or Cleared
  begin
  new_endproduct = EndProductEstablishment.create!(
    veteran_file_number: veteran_file_number,
    claim_id: claim_id
  ).
  # Enqueue a job to sync the new EndProductEstablishment with BGS and VBMS data
  EndProductSyncJob.perform_later(new_endproduct.id)
  new_endproduct.sync!
  rescue StandardError => error
    capture_exception(error: error, (new_endproduct: new_endproduct.id))
  end
end
end
