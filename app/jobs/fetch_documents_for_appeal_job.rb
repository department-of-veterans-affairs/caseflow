# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class FetchDocumentsForAppealJob < ActiveJob::Base
  queue_as :low_priority

  def perform(user, appeals)
    @counts = { docs_cached: 0, docs_failed: 0, appeals_successful: 0, appeals_failed: 0, consecutive_failures: 0 }
    RequestStore.store[:application] = "reader"
    RequestStore.store[:current_user] = user
    update_fetched_at(user)
    fetch_docs_for_appeals(appeals)
    log_info
  end

  def update_fetched_at(user)
    user.update_attributes!(current_appeals_documents_fetched_at: Time.zone.now)
  end

  def fetch_docs_for_appeals(appeals)
    appeals.each do |appeal|
      fetch_docs_for_appeal(appeal)
      break if @counts[:consecutive_failures] >= 5
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
