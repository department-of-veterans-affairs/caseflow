# frozen_string_literal: true

class RetrieveAndCacheReaderDocumentsJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform
    appeals_grouped_by_user = BatchAppealsForReaderQuery.process
    appeals_grouped_by_user.each { |user, tasks| start_fetch_job(user, tasks.map(&:appeal).uniq) }
  end

  def start_fetch_job(user, appeals)
    user.update!(efolder_documents_fetched_at: Time.zone.now)
    log_info(user, appeals)
    if FeatureToggle.enabled?(:cache_reader_documents_nightly)
      FetchDocumentsForReaderJob.new(user: user, appeals: appeals).process
    end
  end

  private

  def log_info(user, appeals)
    Rails.logger.info log_message(user, appeals)
  end

  def log_message(user, appeals)
    "RetrieveAndCacheReaderDocumentsJob - " \
    "User Inspect: (#{user.inspect}) - " \
    "Appeals Count: (#{appeals.count}) - " \
    "Appeals Inspect: (#{appeals.map(&:inspect)})"
  end
end
