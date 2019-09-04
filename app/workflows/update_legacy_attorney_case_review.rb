# frozen_string_literal: true

class UpdateLegacyAttorneyCaseReview
  include ActiveModel::Model

  validates :id, presence: true
  validate :vacols_case_review_exists
  validate :authorized_to_edit
  validate :correct_format

  def initialize(id:, document_id:, user:)
    @id = id
    @document_id = document_id
    @user = user
  end

  def call
    @success = valid?

    if success
      update_attorney_case_review
      update_vacols_decass_table
    end

    FormResponse.new(success: success, errors: [response_errors])
  end

  private

  attr_reader :id, :document_id, :user, :success

  def appeal
    @appeal ||= LegacyAppeal.find_by(vacols_id: id)
  end

  def update_attorney_case_review
    return unless appeal.attorney_case_review

    appeal.attorney_case_review.update!(document_id: document_id)
  end

  def update_vacols_decass_table
    VACOLS::Decass.where(
      defolder: id,
      deadtim: appeal.vacols_case_review_creation_date_in_string_format.to_date
    ).update_all(dedocid: document_id)
  end

  def vacols_case_review_exists
    return if vacols_case_review

    errors.add(:document_id, "Could not find a legacy Attorney Case Review with id #{id}")
  end

  def vacols_case_review
    @vacols_case_review ||= appeal.vacols_case_review
  end

  def authorized_to_edit
    return unless vacols_case_review
    return if allowed_to_edit_legacy_case_review?

    errors.add(:document_id, "You are not authorized to edit this document ID")
  end

  def allowed_to_edit_legacy_case_review?
    LegacyDocumentIdPolicy.new(user: user, case_review: vacols_case_review).editable?
  end

  def correct_format
    return unless vacols_case_review
    return if correct_format?

    errors.add(:document_id, work_product_error_hash[work_product])
  end

  def correct_format?
    if draft_decision_work_product?
      return document_id.match?(new_decision_regex) || document_id.match?(old_decision_regex)
    end

    return document_id.match?(vha_regex) if vha_work_product?

    document_id.match?(ime_regex) if ime_work_product?
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

  def work_product
    vacols_case_review.work_product
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
      "OTD" => invalid_decision_document_id_message
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

  def response_errors
    return if success

    {
      title: COPY::INVALID_RECORD_ERROR_TITLE,
      detail: errors.to_hash[:document_id][0]
    }
  end
end
