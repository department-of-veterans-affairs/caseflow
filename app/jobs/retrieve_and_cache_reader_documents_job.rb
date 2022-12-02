# frozen_string_literal: true

class RetrieveAndCacheReaderDocumentsJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform
    users = BatchUsersForReaderQuery.process
    users.each { |user| start_fetch_job(user) }
  end

  def start_fetch_job(user)
    FetchDocumentsForReaderUserJob.preform_later(user)
  end
end
