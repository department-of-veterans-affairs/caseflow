# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :low_priority

  DEFAULT_USERS_LIMIT = 3
  def perform(args = {})
    RequestStore.store[:application] = "reader"

    # specified limit of users we fetch for
    limit = args["limit"] || DEFAULT_USERS_LIMIT
    find_all_reader_users_by_documents_fetched_at(limit).each do |user|
      start_fetch_job(user)
    end
  end

  def start_fetch_job(user)
    FetchDocumentsForReaderUserJob.perform_later(user)
  end

  def find_all_reader_users_by_documents_fetched_at(limit = 10)
    ReaderUser.all_by_documents_fetched_at(limit)
  end
end
