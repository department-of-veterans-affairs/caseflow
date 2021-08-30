# frozen_string_literal: true

module LegacyAttorneyCaseReviewDocumentIdValidator
  extend ActiveSupport::Concern

  def valid_document_id?
    return false if document_id.nil?

    if draft_decision_work_product?
      return document_id.match?(new_decision_regex) || document_id.match?(old_decision_regex)
    end

    return document_id.match?(vha_regex) if vha_work_product?

    return document_id.match?(ime_regex) if ime_work_product?

    document_id_matches_any?
  end

  def document_id_matches_any?
    document_id.match?(new_decision_regex) ||
      document_id.match?(old_decision_regex) ||
      document_id.match?(vha_regex) ||
      document_id.match?(ime_regex)
  end

  def draft_decision_work_product?
    Constants::DECASS_WORK_PRODUCT_TYPES["DRAFT_DECISION"].include?(work_product)
  end

  def vha_work_product?
    %w[VHA OTV].include?(work_product)
  end

  def ime_work_product?
    %w[IME OTI].include?(work_product)
  end

  def new_decision_regex
    /^\d{5}-\d{8}$/
  end

  def old_decision_regex
    /^\d{8}\.\d{3,4}$/
  end

  def vha_regex
    /^V\d{7}\.\d{3,4}$/
  end

  def ime_regex
    /^M\d{7}\.\d{3,4}$/
  end

  def work_product_error_hash
    {
      "VHA" => invalid_vha_document_id_message,
      "OTV" => invalid_vha_document_id_message,
      "IME" => invalid_ime_document_id_message,
      "OTI" => invalid_ime_document_id_message,
      "DEC" => invalid_decision_document_id_message,
      "OTD" => invalid_decision_document_id_message,
      "DRM" => invalid_decision_document_id_message,
      "AFI" => invalid_decision_document_id_message,
      "BOT" => invalid_decision_document_id_message,
      "COR" => invalid_decision_document_id_message,
      "DAF" => invalid_decision_document_id_message,
      "DEV" => invalid_decision_document_id_message,
      "DIM" => invalid_decision_document_id_message,
      "DOR" => invalid_decision_document_id_message,
      "DVH" => invalid_decision_document_id_message,
      "INT" => invalid_decision_document_id_message,
      "OTB" => invalid_decision_document_id_message,
      "OTH" => invalid_decision_document_id_message,
      "OTR" => invalid_decision_document_id_message,
      "REA" => invalid_decision_document_id_message,
      "REM" => invalid_decision_document_id_message,
      "REU" => invalid_decision_document_id_message,
      "RRC" => invalid_decision_document_id_message,
      "SUP" => invalid_decision_document_id_message,
      "VAC" => invalid_decision_document_id_message,
      "VDC" => invalid_decision_document_id_message,
      "VDR" => invalid_decision_document_id_message,
      "VDS" => invalid_decision_document_id_message,
      "VRM" => invalid_decision_document_id_message
    }
  end

  def invalid_vha_document_id_message
    "VHA Document IDs must be in one of these formats: V1234567.123 or V1234567.1234"
  end

  def invalid_ime_document_id_message
    "IME Document IDs must be in one of these formats: M1234567.123 or M1234567.1234"
  end

  def invalid_decision_document_id_message
    "Draft Decision Document IDs must be in one of these formats: " \
      "12345-12345678 or 12345678.123 or 12345678.1234"
  end
end
