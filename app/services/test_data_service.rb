# Service used to reset test data used in integration smoke tests
# Code is not tested in isolation so remove from code cov requirement
class TestDecisionDocument
  include UploadableDocument

  def document_type
    "BVA Decision"
  end

  def pdf_location
    Rails.root.join "spec", "support", "bva-decision-TEST.pdf"
  end
end

class TestDataService
  class WrongEnvironmentError < StandardError; end

  def self.prepare_claims_establishment!(vacols_id:, cancel_eps: false)
    return false if ApplicationController.dependencies_faked?
    fail WrongEnvironmentError unless Rails.deploy_env?(:uat)

    log "Preparing case with VACOLS id of #{vacols_id} for claims establishment"

    # Push the decision date to the current date in vacols
    vacols_case = VACOLS::Case.find(vacols_id)
    vacols_case.update_attributes(bfddec: AppealRepository.dateshift_to_utc(Time.zone.now))

    # Upload decision document for the appeal if it isn't there
    log "Uploading decision for file #{vacols_case.bfcorlid}"
    appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
    AppealRepository.upload_document(appeal, TestDecisionDocument.new) unless appeal.decision

    cancel_end_products(appeal) if cancel_eps
  end

  # Cancel all EPs for an appeal to prevent duplicates
  def self.cancel_end_products(appeal)
    appeal.pending_eps.each do |end_product|
      log "Cancelling EP #{end_product[:end_product_type_code]} - #{end_product[:claim_type_code]}"
      appeal.bgs.client.claims.cancel_end_product(
        file_number: appeal.sanitized_vbms_id,
        end_product_code: end_product[:claim_type_code],
        modifier: end_product[:end_product_type_code]
      )
    end
  end

  def self.log(message)
    Rails.logger.info message
  end
end
