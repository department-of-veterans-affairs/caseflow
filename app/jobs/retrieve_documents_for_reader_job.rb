# frozen_string_literal: true

# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ApplicationJob
  queue_as :low_priority
  application_attr :reader

  def perform
    find_all_reader_users_by_documents_fetched_at.each do |user|
      start_fetch_job(user)
    end
  end

  def start_fetch_job(user)
    FetchDocumentsForReaderUserJob.perform_later(user)
  end

  def find_all_reader_users_by_documents_fetched_at
    ReaderUser.all_by_documents_fetched_at
  end
end
