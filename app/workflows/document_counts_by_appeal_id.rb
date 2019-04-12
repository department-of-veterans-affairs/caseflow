# frozen_string_literal: true

class DocumentCountsByAppealIdHash
  def initialize(hash:, appeal_ids:)
    @hash = hash
    @appeal_ids = appeal_ids
  end

  def call
    build_document_counts_hash(hash)
  end

  private

  def build_document_counts_hash(document_counts_by_id_hash)
    params[:appeal_ids].split(",").each do |appeal_id|
      begin
        set_document_count_value_for_appeal_id(document_counts_by_id_hash, appeal_id)
      rescue StandardError => err
        handle_document_count_error(err, document_counts_by_id_hash, appeal_id)
        next
      end
    end
    document_counts_by_id_hash
  end

  def handle_document_count_error(err, document_counts_by_id_hash, appeal_id)
    err_obj = serialize_error(err)
    document_counts_by_id_hash[appeal_id] = {
      error: err_obj[:err], status: err_obj[:code], count: nil
    }
  end

  def set_document_count_value_for_appeal_id(hash, appeal_id)
    hash[appeal_id] = {
      count: Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
        .number_of_documents,
      status: 200,
      error: nil
    }
    hash
  end
end
