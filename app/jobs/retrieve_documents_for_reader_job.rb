# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :low_priority

  DEFAULT_USERS_LIMIT = 10

  def perform(args = {})
    RequestStore.store[:application] = "reader"

    # specified limit of users we fetch for
    limit = args["limit"] || DEFAULT_USERS_LIMIT

    find_all_active_reader_appeals(limit).each do |user, appeals|
      start_fetch_job(user, appeals)
    end
  end

  def start_fetch_job(user, appeals)
    if Rails.env.development? || Rails.env.test?
      FetchDocumentsForAppealJob.perform_now(user, appeals)
    else
      # in prod, we run this asynchronously. Through shoryuken we retry and have exponential backoff
      FetchDocumentsForAppealJob.perform_later(user, appeals)
    end
  end

  def find_all_active_reader_appeals(limit = 10)
    ReaderUser.all_by_documents_fetched_at(limit).reduce({}) do |active_appeals, user|
      active_appeals.update(user => user.user.current_case_assignments)
    end
  end

end
