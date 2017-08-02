require "set"

class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :default

  def perform(args = {})
    RequestStore.store[:application] = "reader"

    # Args should be set in sidekiq_cron.yml, but default the limit to 1500 if they aren't
    limit = args["limit"] || 1500
    counts = { docs_successful_count: 0, docs_failed_count: 0, docs_attempted: 0, appeals_failed_count: 0 }

    find_all_active_reader_appeals.each do |appeal|
      begin
        appeal.fetch_documents!(save: true).each do |doc|
          counts[:docs_attempted] += 1
          fetch_document_content(doc) ? counts[:docs_successful_count] += 1 : counts[:docs_failed_count] += 1
        end
      rescue HTTPClient::KeepAliveDisconnected => e
        # VBMS connection may die when attempting to retrieve list of docs for appeal
        counts[:appeals_failed_count] += 1
        Rails.logger.error "Failed to retrieve appeal id #{appeal.id}:\n#{e.message}"
      end

      break if counts[:docs_attempted] >= limit
    end

    log_info(counts)
  end

  def find_all_active_reader_appeals
    User.where("'Reader' = ANY(roles)").reduce(Set.new) do |active_appeals, user|
      active_appeals.merge(user.current_case_assignments)
    end
  end

  def fetch_document_content(doc)
    doc.fetch_content unless S3Service.exists?(doc.file_name)
  rescue Aws::S3::Errors::ServiceError, VBMS::ClientError => e
    Rails.logger.error "Failed to retrieve #{doc.file_name}:\n#{e.message}"
  end

  def log_info(counts)
    output_msg = "RetrieveDocumentsForReaderJob successfully retrieved #{counts[:docs_successful_count]} documents " \
          "and #{counts[:docs_failed_count]} document(s) failed. #{counts[:appeals_failed_count]} appeal(s) failed."
    Rails.logger.info output_msg
    SlackService.new(url: slack_url).send_notification(output_msg)
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end
end
