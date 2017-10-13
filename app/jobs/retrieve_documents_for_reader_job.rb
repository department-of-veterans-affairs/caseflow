# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :low_priority

  DEFAULT_DOCUMENTS_DOWNLOADED_LIMIT = 1500

  def perform(args = {})
    RequestStore.store[:application] = "reader"

    # Args should be set in cron configuration in ansible, but default the limit to 1500 if they aren't
    limit = args["limit"] || DEFAULT_DOCUMENTS_DOWNLOADED_LIMIT
    @counts = { docs_cached: 0, docs_failed: 0, appeals_successful: 0, appeals_failed: 0, consecutive_failures: 0 }

    find_all_active_reader_appeals.each do |user, appeals|
      RequestStore.store[:current_user] = user
      appeals.each { |appeal| fetch_docs_for_appeal(appeal) }

      break if @counts[:docs_cached] >= limit || @counts[:consecutive_failures] >= 5
    end

    log_info
  end

  def find_all_active_reader_appeals
    User.where("'Reader' = ANY(roles)").reduce({}) do |active_appeals, user|
      active_appeals.update(user => user.current_case_assignments)
    end
  end

  def fetch_docs_for_appeal(appeal)
    appeal.fetch_documents!(save: true).try(:each) { |doc| cache_document(doc) }
    @counts[:appeals_successful] += 1
  rescue HTTPClient::KeepAliveDisconnected, VBMS::ClientError => e
    # VBMS connection may die when attempting to retrieve list of docs for appeal
    @counts[:appeals_failed] += 1
    @counts[:consecutive_failures] += 1
    Rails.logger.error "Failed to retrieve appeal id #{appeal.id}:\n#{e.message}"
  end

  # Checks if the doc is already stored in S3 and fetches it from VBMS if necessary.  If eFolder is enabled,
  # skip this check since the call to eFolder in fetch_docs_for_appeal is supposed to cache the doc for us
  #
  # Returns a boolean if the content has been cached without errors
  def cache_document(doc)
    if !FeatureToggle.enabled?(:efolder_docs_api) && !S3Service.exists?(doc.file_name)
      doc.fetch_content
      @counts[:docs_cached] += 1
      @counts[:consecutive_failures] = 0
    end
  rescue Aws::S3::Errors::ServiceError, VBMS::ClientError => e
    Rails.logger.error "Failed to retrieve #{doc.file_name}:\n#{e.message}"
    @counts[:docs_failed] += 1
    @counts[:consecutive_failures] += 1
  end

  def log_info
    output_msg = "RetrieveDocumentsForReaderJob successfully retrieved #{@counts[:docs_cached]} documents " \
          "for #{@counts[:appeals_successful]} appeals and #{@counts[:docs_failed]} document(s) failed.\n" \
          "Failed to retrieve documents for #{@counts[:appeals_failed]} appeal(s)."

    if @counts[:consecutive_failures] >= 5
      output_msg += "\nJob stopped after #{@counts[:consecutive_failures]} failures"
    end

    Rails.logger.info output_msg
    SlackService.new(url: slack_url).send_notification(output_msg)
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end
end
