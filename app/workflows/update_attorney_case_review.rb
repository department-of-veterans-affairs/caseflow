# frozen_string_literal: true

class UpdateAttorneyCaseReview
  include ActiveModel::Model
  include ::AmaAttorneyCaseReviewDocumentIdValidator

  validates :id, presence: true
  validate :attorney_case_review_exists
  validate :authorized_to_edit

  def initialize(id:, document_id:, user:)
    @id = id
    @document_id = document_id
    @user = user
  end

  def call
    @success = valid?

    case_review.update!(document_id: document_id) if success

    FormResponse.new(success: success, errors: [response_errors])
  end

  private

  attr_reader :id, :document_id, :user, :success
  attr_writer :document_id

  def case_review
    @case_review ||= AttorneyCaseReview.find_by(id: id)
  end

  def attorney_case_review_exists
    return if case_review

    errors.add(:attorney_case_review, "id #{id} could not be found")
  end

  def authorized_to_edit
    return unless case_review
    return if allowed_to_edit_ama_case_review?

    errors.add(:user, "not authorized to edit this document ID")
  end

  def allowed_to_edit_ama_case_review?
    AmaDocumentIdPolicy.new(user: user, case_review: case_review).editable?
  end

  def correct_ama_document_id
    # binding.pry
    return unless case_review
    return if correct_format?

    errors.add(:document_id, work_product_error_hash[work_product])
  end

  def work_product
    case_review.work_product
  end

  def response_errors
    return if success

    {
      title: COPY::INVALID_RECORD_ERROR_TITLE,
      detail: errors.full_messages.join(", ")
    }
  end
end
