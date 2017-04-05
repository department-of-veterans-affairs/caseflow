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

  def self.reset_appeal_special_issues
    return false if ApplicationController.dependencies_faked?

    fail WrongEnvironmentError unless Rails.deploy_env?(:uat) || Rails.deploy_env?(:preprod)

    Appeal.find_each do |appeal|
      Appeal::SPECIAL_ISSUES.keys.each do |special_issue|
        appeal.send("#{special_issue}=", false)
      end
      appeal.save
    end
  end

  def self.prepare_claims_establishment!(vacols_id:, cancel_eps: false, decision_type: :partial)
    return false if ApplicationController.dependencies_faked?
    fail WrongEnvironmentError unless Rails.deploy_env?(:uat)
    # Cancel EPs
    appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
    cancel_end_products(appeal) if cancel_eps
    log "Preparing case with VACOLS id of #{vacols_id} for claims establishment"
    vacols_case = VACOLS::Case.find(vacols_id)
    if decision_type == :full
      dec_date = AppealRepository.dateshift_to_utc(2.days.ago)
    else
      dec_date = AppealRepository.dateshift_to_utc(10.days.ago)
      # Partial grants change location, need to set it back
      reset_location(vacols_case)
    end
    # Push the decision date in VACOLS:
    vacols_case.update_attributes(bfddec: dec_date)
    reset_outcoding_date(vacols_case: vacols_case, date: dec_date)
    upload_decision_doc(vacols_id: vacols_id, date: dec_date)
  end

  def self.upload_decision_doc(vacols_id: nil, date: Timezone.now)
    return false if vacols_id.nil?
    # Upload test decision document for the date
    appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
    vbms_client ||= AppealRepository.init_vbms_client
    uploadable_document = TestDecisionDocument.new
    log "Uploading decision for #{appeal.sanitized_vbms_id}"
    upload_request = VBMS::Requests::UploadDocumentWithAssociations.new(appeal.sanitized_vbms_id,
                                                                        date,
                                                                        appeal.veteran_first_name,
                                                                        appeal.veteran_middle_initial,
                                                                        appeal.veteran_last_name,
                                                                        uploadable_document.document_type,
                                                                        uploadable_document.pdf_location,
                                                                        uploadable_document.document_type_id,
                                                                        "VACOLS",
                                                                        true)
    upload_resp = vbms_client.send_request(upload_request)
    log "VBMS Test Decision Document upload response: #{upload_resp}"
  end

  # Cancel all EPs for an appeal to prevent duplicates
  def self.cancel_end_products(appeal)
    appeal.pending_eps.each do |end_product|
      log "Cancelling EP #{end_product.modifier} - #{end_product.claim_type_code}"
      Appeal.bgs.client.claims.cancel_end_product(
        file_number: appeal.sanitized_vbms_id,
        end_product_code: end_product.claim_type_code,
        modifier: end_product.modifier
      )
    end
  end

  def self.reset_outcoding_date(vacols_case: nil, date: 2.days.ago)
    return false if vacols_case.nil?
    conn = vacols_case.class.connection
    # Note: we usee conn.quote here from ActiveRecord to deter SQL injection
    case_id = conn.quote(vacols_case)
    date_fmt = conn.quote(date)
    MetricsService.record("VACOLS: reset decision date for #{case_id}",
                          service: :vacols,
                          name: "reset_outcoding_date") do
      conn.transaction do
        conn.execute(<<-SQL)
          UPDATE FOLDER
          SET TIOCTIME = #{date_fmt}
          WHERE TICKNUM = #{case_id}
        SQL
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.reset_location(vacols_case)
    conn = vacols_case.class.connection
    # Note: we usee conn.quote here from ActiveRecord to deter SQL injection
    case_id = conn.quote(vacols_case)
    MetricsService.record("VACOLS: reset decision date for #{case_id}",
                          service: :vacols,
                          name: "reset_location") do
      conn.transaction do
        conn.execute(<<-SQL)
          UPDATE BRIEFF
          SET BFDLOCIN = SYSDATE,
              BFCURLOC = '97',
              BFDLOOUT = SYSDATE,
              BFORGTIC = NULL
          WHERE BFKEY = #{case_id}
        SQL
        conn.execute(<<-SQL)
          UPDATE PRIORLOC
          SET LOCDIN = SYSDATE,
              LOCSTRCV = 'DSUSER',
              LOCEXCEP = 'Y'
          WHERE LOCKEY = #{case_id} and LOCDIN is NULL
        SQL
        conn.execute(<<-SQL)
          INSERT into PRIORLOC
            (LOCDOUT, LOCDTO, LOCSTTO, LOCSTOUT, LOCKEY)
          VALUES
           (SYSDATE, SYSDATE, '97', 'DSUSER', #{case_id})
        SQL
      end
    end
  end

  def self.delete_test_data
    # Only prepare test if there are less than 20 EstablishClaim tasks, as additional safeguard
    fail "Too many ClaimsEstablishment tasks" if EstablishClaim.count > 50
    EstablishClaim.delete_all
    Task.delete_all
    Appeal.delete_all
  end

  def self.log(message)
    Rails.logger.info message
  end
end
