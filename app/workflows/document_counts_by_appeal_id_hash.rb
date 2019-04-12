# frozen_string_literal: true

class DocumentCountsByAppealIdHash
  include ActiveModel::Model

  def initialize(hash:, appeal_ids:)
    @hash = hash
    @appeal_ids = appeal_ids
  end

  def call
    build_document_counts_hash(@hash, @appeal_ids)
  end

  private

  # def build_document_counts_hash
  #   document_counts_hash = {}

  # end

  def build_document_counts_hash(document_counts_by_id_hash, appeal_ids)
    # Collect appeal objects sequentially so we don't exhaust DB pool
    appeals = appeal_ids.each_with_object({}) do |appeal_id, result|
      result[appeal_id] = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
    end

    # Spin up a new thread of each appeal and then call join on each thread
    # Creating threads without calling join on them will cause the main thread
    # to continue without waiting and possibly exit before the child threads have finished
    appeals.map do |appeal_id, appeal|
      Thread.new do
        begin
          set_document_count_value_for_appeal_id(document_counts_by_id_hash, appeal_id, appeal)
        rescue StandardError => err
          handle_document_count_error(err, document_counts_by_id_hash, appeal_id)
          next
        end
      end
    end.map(&:join)
    document_counts_by_id_hash
  end

  def handle_document_count_error(err, document_counts_by_id_hash, appeal_id)
    err_obj = serialize_error(err)
    document_counts_by_id_hash[appeal_id] = {
      error: err_obj[:err], status: err_obj[:code], count: nil
    }
  end

  def set_document_count_value_for_appeal_id(hash, appeal_id, appeal)
    hash[appeal_id] = {
      count: appeal.number_of_documents,
      status: 200,
      error: nil
    }
    hash
  end

  def serialize_error(err)
    error_type = err.class.name
    code = (err.class == ActiveRecord::RecordNotFound) ? 404 : 500
    {
      code: code,
      err: error_type
    }
  end
end
