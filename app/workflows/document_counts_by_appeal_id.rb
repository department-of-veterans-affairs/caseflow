# frozen_string_literal: true

class DocumentCountsByAppealId
  def initialize(appeal_ids:)
    @document_counts_by_appeal_id_hash = {}
    @appeal_ids = appeal_ids
  end

  def call
    if @appeal_ids.length > Constants::REQUEST_CONSTANTS["max_batch_size"]
      fail Caseflow::Error::TooManyAppealIds
    end

    build_document_counts_hash(@appeal_ids)
    @document_counts_by_appeal_id_hash
  end

  private

  def build_document_counts_hash(appeal_ids)
    # Collect appeal objects sequentially so we don't exhaust DB pool
    appeals_hash = collect_appeal_objects_sequentially(appeal_ids)
    # Spin up a new thread of each appeal and then call join on each thread
    # Creating threads without calling join on them will cause the main thread
    # to continue without waiting and possibly exit before the child threads have finished
    create_thread_for_each_appeal(appeals_hash)
  end

  def collect_appeal_objects_sequentially(appeal_ids)
    appeal_ids.each_with_object({}) do |appeal_id, result|
      result[appeal_id] = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
    end
  end

  def create_thread_for_each_appeal(appeals_hash)
    appeals_hash.map do |appeal_id, appeal|
      create_thread_for_appeal(appeal_id, appeal)
    end.map(&:join)
  end

  def create_thread_for_appeal(appeal_id, appeal)
    Thread.new do
      begin
        set_document_count_value_for_appeal_id(appeal_id, appeal)
      rescue StandardError => error
        # We will send all these errors to Sentry for the time being
        # until we are sure our code works
        Raven.capture_exception(error)
        handle_document_count_error(error, appeal_id)
        next
      end
    end
  end

  def handle_document_count_error(error, appeal_id)
    error = ApplicationHelper.handle_non_critical_error("document_count", error)
    @document_counts_by_appeal_id_hash[appeal_id] = error.to_simple_hash
  end

  def set_document_count_value_for_appeal_id(appeal_id, appeal)
    @document_counts_by_appeal_id_hash[appeal_id] = {
      count: appeal.number_of_documents,
      status: 200
    }
  end
end
