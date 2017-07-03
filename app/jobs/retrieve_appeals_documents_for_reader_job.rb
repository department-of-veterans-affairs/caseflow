class RetrieveAppealsDocumentsForReaderJob < ActiveJob::Base
  queue_as :default

  def perform
    Rails.logger.info "Retrieving documents for appeals assigned to Reader users"
    @count = 0

    User.where("'Reader' = ANY(roles)").each do |user|
      user.current_case_assignments.each do |appeal|
        appeal.fetch_documents!(save: true).each do |document|
          Rails.logger.debug 'Fetching #{document.file_name} from VBMS'
          document.fetch_and_cache_document_from_vbms
        end
      end

      @count += 1
    end

    Rails.logger.info "Successfully retrieved #{@count} users documents"
  end
end
