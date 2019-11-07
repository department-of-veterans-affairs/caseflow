# frozen_string_literal: true

# This job will retrieve cases from VACOLS and cases from Caseflow tasks
# and all documents for these cases in VBMS and store them
class FetchDocumentsForReaderUserJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform(user)
    user.update!(efolder_documents_fetched_at: Time.zone.now)
    appeals = AppealsForReaderJob.new(user).process
    FetchDocumentsForReaderJob.new(user: user, appeals: appeals).process
  end
end
