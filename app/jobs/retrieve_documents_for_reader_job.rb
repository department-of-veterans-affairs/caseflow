# frozen_string_literal: true

# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform
    users = BatchUsersForReaderQuery.process
    users.each { |user| start_fetch_job(user) }
  end

  def start_fetch_job(user)
    FetchDocumentsForReaderUserJob.perform_later(user)
  end
end
