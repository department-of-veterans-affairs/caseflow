# frozen_string_literal: true

class UpdateLegacyAttorneyCaseReview
  include ActiveModel::Model
  include ::LegacyAttorneyCaseReviewDocumentIdValidator

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
  delegate :work_product, to: :vacols_case_review

  def update_attorney_case_review
    return unless attorney_case_review

    attorney_case_review.update!(document_id: document_id)
  end

  def attorney_case_review
    AttorneyCaseReview.find_by(task_id: "#{id}-#{vacols_case_review_creation_date_in_string_format}")
  end

  def update_vacols_decass_table
    VACOLS::Decass.where(
      defolder: id,
      deadtim: vacols_case_review_creation_date_in_vacols_format
    ).update_all(dedocid: document_id)
  end

  def vacols_case_review_creation_date_in_vacols_format
    vacols_case_review_creation_date_in_string_format.to_date
  end

  def vacols_case_review_creation_date_in_string_format
    VacolsHelper.day_only_str(vacols_case_review.created_at)
  end

  def vacols_case_review_exists
    return if vacols_case_review

    errors.add(:document_id, "Could not find a legacy Attorney Case Review with id #{id}")
  end

  def vacols_case_review
    @vacols_case_review ||= VACOLS::CaseAssignment.latest_task_for_appeal(id)
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
    # binding.pry
    return unless vacols_case_review
    return if valid_document_id?

    errors.add(:document_id, work_product_error_hash[work_product])
  end

  def response_errors
    return if success

    {
      title: COPY::INVALID_RECORD_ERROR_TITLE,
      detail: errors.to_hash[:document_id][0]
    }
  end
end
