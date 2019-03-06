# frozen_string_literal: true

module AmaAttorneyCaseReviewDocumentIdValidator
  extend ActiveSupport::Concern

  included do
    validate :correct_ama_document_id, if: :document_id
  end

  private

  def correct_ama_document_id
    return if correct_format?

    errors.add(:document_id, work_product_error_hash[work_product])
  end

  def correct_format?
    self.document_id = document_id.strip

    if decision_work_product?
      return document_id.match?(new_decision_regex) || document_id.match?(old_decision_regex)
    end

    return document_id.match?(vha_regex) if vha_work_product?

    document_id.match?(ime_regex) if ime_work_product?
  end

  def decision_work_product?
    work_product == "Decision"
  end

  def vha_work_product?
    work_product == "OMO - VHA"
  end

  def ime_work_product?
    work_product == "OMO - IME"
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
      "OMO - VHA" => "of type VHA must be in one of these formats: " \
                     "V1234567.123 or V1234567.1234",
      "OMO - IME" => "of type IME must be in one of these formats: " \
                     "M1234567.123 or M1234567.1234",
      "Decision" => "of type Draft Decision must be in one of these formats: " \
                    "12345-12345678 or 12345678.123 or 12345678.1234"
    }
  end
end
