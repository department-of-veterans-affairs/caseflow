# frozen_string_literal: true

# This job will retrieve cases from VACOLS and cases from Caseflow tasks
# and all documents for these cases in VBMS and store them
class FetchDocumentsForReaderUserJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform(user)
    user.update!(efolder_documents_fetched_at: Time.zone.now)
    appeals = AppealsForReaderJob.new(user).process

    log_info(user, appeals)

    FetchDocumentsForReaderJob.new(user: user, appeals: appeals).process
  end

  private

  def log_info(user, appeals)
    Rails.logger.info log_message(user, appeals)
  end

  def log_message(user, appeals)
    "FetchDocumentsForReaderUserJob - " \
    "User Inspect: (#{user.inspect}) - " \
    "Appeals Count: (#{appeals.count}) - " \
    "Appeals Inspect: (#{appeals.map(&:inspect)})"
  end
end
