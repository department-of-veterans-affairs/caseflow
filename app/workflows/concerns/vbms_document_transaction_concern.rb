# frozen_string_literal: true

# Houses common methods used for uploading and updating documents in VBMS eFolder
module VbmsDocumentTransactionConcern
  extend ActiveSupport::Concern

  # :reek:FeatureEnvy
  def persist_efolder_version_info(response, response_key)
    document.update!(
      document_version_reference_id: response.dig(response_key, :@new_document_version_ref_id),
      document_series_reference_id: response.dig(response_key, :@document_series_ref_id)
    )
  end

  def throw_error_if_file_number_not_match_bgs
    bgs_file_number = nil
    if !veteran_file_number.nil?
      bgs_file_number = bgs_service.fetch_file_number_by_ssn(veteran_ssn)
    end
    if bgs_service.fetch_veteran_info(veteran_file_number).nil?
      if !bgs_file_number.blank? && !bgs_service.fetch_veteran_info(bgs_file_number).nil?
        bgs_file_number
      else
        fail(
          Caseflow::Error::BgsFileNumberMismatch,
          file_number: veteran_file_number, user_id: user.id
        )
      end
    else
      veteran_file_number
    end
  end
end
