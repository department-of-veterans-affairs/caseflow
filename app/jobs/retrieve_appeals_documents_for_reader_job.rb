class RetrieveAppealsDocumentsForReaderJob < ActiveJob::Base
  queue_as :default

  def perform
  	Rails.logger.info 'Retrieving documents for appeals assigned to Reader users'
  	@count = 0

    User.where("'Reader' = ANY(roles)").each do | user |
      user.current_case_assignments.fetch_documents!(save: true)
      @count += 1
    end
    
    Rails.logger.info "Successfully retrieved #{@count} users documents"
  end
end
