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
      Appeal::SPECIAL_ISSUE_COLUMNS.each do |special_issue|
        appeal.send("#{special_issue}=", false)
      end
      appeal.save
    end
  end

  def self.prepare_claims_establishment!(vacols_id:, cancel_eps: false, decision_type: :partial)
    return false if ApplicationController.dependencies_faked?
    fail WrongEnvironmentError unless Rails.deploy_env?(:uat)

    log "Preparing case with VACOLS id of #{vacols_id} for claims establishment"

    # Push the decision date to the current date in vacols
    # Update location to what it should be initially
    vacols_case = VACOLS::Case.find(vacols_id)
    if decision_type == :full
      vacols_case.update_attributes(bfddec: AppealRepository.dateshift_to_utc(2.days.ago))
      # Full Grants stay 99 but need to be moved up to at least -3 days
      reset_outcoding_date(vacols_case)
    else
      vacols_case.update_attributes(bfddec: AppealRepository.dateshift_to_utc(10.days.ago))
      reset_location(vacols_case)
    end

    # Upload decision document for the appeal if it isn't there
    log "Uploading decision for file #{vacols_case.bfcorlid}"
    appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
    AppealRepository.upload_document(appeal, TestDecisionDocument.new) if appeal.decisions.empty?

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

  def self.reset_outcoding_date(vacols_case)
    conn = vacols_case.class.connection
    # Note: we usee conn.quote here from ActiveRecord to deter SQL injection
    case_id = conn.quote(vacols_case)
    MetricsService.timer "VACOLS: reset decision date for #{case_id}" do
      conn.transaction do
        conn.execute(<<-SQL)
          UPDATE FOLDER
          SET TIOCTIME = (SYSDATE-2)
          WHERE TICKNUM = #{case_id}
        SQL
      end
    end
  end

  def self.reset_location(vacols_case)
    conn = vacols_case.class.connection
    # Note: we usee conn.quote here from ActiveRecord to deter SQL injection
    case_id = conn.quote(vacols_case)
    MetricsService.timer "VACOLS: reset decision date for #{case_id}" do
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
