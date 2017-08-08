# This job will retrieve cases from VACOLS via the CaseAssignmentRepository
# and all documents for these cases in VBMS and store these
class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :default

  DEFAULT_DOCUMENTS_DOWNLOADED_LIMIT = 1500

  def perform(args = {})
    RequestStore.store[:application] = "reader"

    # Args should be set in sidekiq_cron.yml, but default the limit to 1500 if they aren't
    limit = args["limit"] || DEFAULT_DOCUMENTS_DOWNLOADED_LIMIT
    @counts = { docs_successful: 0, docs_failed: 0, docs_attempted: 0, appeals_failed: 0, consecutive_failures: 0 }

    find_all_active_reader_appeals.each do |user, appeals|
      RequestStore.store[:current_user] = user
      appeals.each { |appeal| fetch_docs_for_appeal(appeal) }

      break if @counts[:docs_attempted] >= limit || @counts[:consecutive_failures] >= 5
    end

    log_info
  end

  def record_doc_outcome(doc)
    if doc
      @counts[:docs_successful] += 1
      @counts[:consecutive_failures] = 0
    else
      @counts[:docs_failed] += 1
      @counts[:consecutive_failures] += 1
    end
  end

  def find_all_active_reader_appeals
    User.where("'Reader' = ANY(roles)").reduce({}) do |active_appeals, user|
      active_appeals.update(user => user.current_case_assignments)
    end
  end

  def fetch_docs_for_appeal(appeal)
    appeal.fetch_documents!(save: true).try(:each) do |doc|
      @counts[:docs_attempted] += 1
      record_doc_outcome(fetch_document_content(doc))
    end
  rescue HTTPClient::KeepAliveDisconnected => e
    # VBMS connection may die when attempting to retrieve list of docs for appeal
    @counts[:appeals_failed] += 1
    @counts[:consecutive_failures] += 1
    Rails.logger.error "Failed to retrieve appeal id #{appeal.id}:\n#{e.message}"
  end

  def fetch_document_content(doc)
    if FeatureToggle.enabled?(:efolder_docs_api)
      true # Don't fetch the content since eFolder will begin downloading the case automatically
    else
      doc.fetch_content_unless_cached
    end
  rescue Aws::S3::Errors::ServiceError, VBMS::ClientError => e
    Rails.logger.error "Failed to retrieve #{doc.file_name}:\n#{e.message}"
  end

  def log_info
    output_msg = "RetrieveDocumentsForReaderJob successfully retrieved #{@counts[:docs_successful]} documents " \
          "and #{@counts[:docs_failed]} document(s) failed. #{@counts[:appeals_failed]} appeal(s) failed."

    output_msg = "\nJob stopped after #{@counts[:consecutive_failures]} failures" if @counts[:consecutive_failures] >= 5

    Rails.logger.info output_msg
    SlackService.new(url: slack_url).send_notification(output_msg)
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end
end
