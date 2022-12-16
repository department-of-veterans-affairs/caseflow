# frozen_string_literal: true

# This job will retrieve cases from VACOLS and cases from Caseflow tasks
# and all documents for these cases in VBMS and store them
class FetchDocumentsForReaderUserJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :reader

  def perform(user)
    user.update!(efolder_documents_fetched_at: Time.zone.now)
    appeals = AppealsForReaderJob.new(user).process

    # Logger to identify what Appeals are being fetched
    # we need appeal, user, docs, efolder_size

    FetchDocumentsForReaderJob.new(user: user, appeals: appeals).process
    # documents = appeals.map(&:documents).flatten

    CaseflowLogger.log('FetchDocumentsForReaderUserJob',
      user: user.inspect,
      appeals_count: appeals.count,
      appeals: appeals.map(&:inspect))

    # Rails.logger.info(
    #   "ReaderJobCurrent - FetchDocumentForReaderUserJob " \
    #   "Appeals Fetched: (#{appeals.count})" \
    #   "User: (#{user})" \
    #   "Document ID: #{documents.map(&:id)}" \
    #   "Document File Number: #{documents.map(&:file_number)}" \
    #   "Document VBMS Document ID: #{documents.map(&:vbms_document_id)}"
    # )
  end
end
