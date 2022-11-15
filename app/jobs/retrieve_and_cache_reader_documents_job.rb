# frozen_string_literal: true

class RetrieveAndCacheReaderDocumentsJob < ApplicationJob
  queue_with_priority :low_priority
<<<<<<< HEAD
  application_attr :reader

  def perform
    users = BatchUsersForReaderQuery.process
    users.each { |user| start_fetch_job(user) }
  end

  def start_fetch_job(user)
    FetchDocumentsForReaderUserJob.preform_later(user)
  end
=======
  def perform; end
>>>>>>> 02fe730e1 (reverted misspelling changes)
end
