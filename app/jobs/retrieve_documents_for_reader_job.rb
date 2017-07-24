require "set"

class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :default

  def perform(args = {})
    # Args should be set in sidekiq_cron.yml, but default the limit to 1500 if they aren't
    limit = args[:limit] || 1500
    successful_count = 0
    failed_count = 0
    docs_attempted = 0

    find_all_active_reader_appeals.each do |appeal|
      appeal.fetch_documents!(save: true).each do |document|
        begin
          unless S3Service.exists?(document.file_name)
            docs_attempted += 1
            successful_count += 1 if document.fetch_content
          end
        rescue Aws::S3::Errors::ServiceError, VBMS::ClientError => e
          failed_count += 1
          Rails.logger.error "Failed to retrieve #{document.file_name}:\n#{e.message}"
        end
      end

      break if docs_attempted >= limit
    end

    Rails.logger.info "Successfully retrieved #{successful_count} documents for Reader cases"
    Rails.logger.info "#{failed_count} documents failed"
  end

  def find_all_active_reader_appeals
    User.where("'Reader' = ANY(roles)").reduce(Set.new) do |active_appeals, user|
      active_appeals.merge(user.current_case_assignments)
    end
  end
end
