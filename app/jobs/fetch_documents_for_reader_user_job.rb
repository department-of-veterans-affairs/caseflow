# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class FetchDocumentsForReaderUserJob < ApplicationJob
  queue_as :low_priority
  application_attr :reader

  # if a user has experienced more than DOCUMENT_FAILURE_COUNT, we consider this job as failed
  DOCUMENT_FAILURE_COUNT = 5

  def perform(reader_user)
    @counts = {
      appeals_total: 0,
      appeals_successful: 0
    }

    setup_debug_context(reader_user)
    update_fetched_at(reader_user)
    legacy_appeals = reader_user.user.current_case_assignments

    ama_user_tasks = Task.active.where(assigned_to: reader_user.user)
    ama_appeals = ama_user_tasks.map(&:appeal).uniq

    fetch_documents_for_appeals(legacy_appeals + ama_appeals)
    log_info
  rescue StandardError => e
    log_error
    # raising an exception here triggers a retry through shoryuken
    raise e
  end

  def setup_debug_context(reader_user)
    current_user = reader_user.user
    RequestStore.store[:current_user] = current_user
    Raven.extra_context(application: "reader")
    Raven.user_context(
      email: current_user.email,
      css_id: current_user.css_id,
      regional_office: current_user.regional_office,
      reader_user: reader_user.id
    )
    Rails.logger.debug("Fetching docs for reader_user: #{reader_user.id}, user: #{current_user.id}")
  end

  def update_fetched_at(reader_user)
    reader_user.update!(documents_fetched_at: Time.zone.now)
  end

  def fetch_documents_for_appeals(appeals)
    @counts[:appeals_total] = appeals.count
    appeals.each do |appeal|
      Raven.extra_context(appeal_id: appeal.id)
      Rails.logger.debug("Fetching docs for appeal #{appeal.id}")

      # signal to efolder X to fetch and save all documents
      appeal.document_fetcher.find_or_create_documents!
      @counts[:appeals_successful] += 1
    rescue Caseflow::Error::EfolderAccessForbidden
      Rails.logger.error "Encountered access forbidden error when fetching documents for appeal #{appeal.id}"
      next
    rescue Caseflow::Error::ClientRequestError, Caseflow::Error::DocumentRetrievalError
      Rails.logger.error "Encountered client request error when fetching documents for appeal #{appeal.id}"
      next
    end
  end

  def log_info
    Rails.logger.info log_message
  end

  def log_error
    Rails.logger.error log_message("ERROR")
  end

  def log_message(status = "SUCCESS")
    "FetchDocumentsForReaderUserJob (user_id: #{RequestStore[:current_user].id}) #{status}. " \
      "Retrieved #{@counts[:appeals_successful]} / #{@counts[:appeals_total]} appeals"
  end
end
