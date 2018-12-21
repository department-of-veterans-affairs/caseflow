class UpdateAttorneyCaseReview
  include ActiveModel::Model

  validates :id, presence: true
  validate :authorized_to_edit
  validate :correct_format

  def initialize(id:, document_id:, user_id:)
    @id = id
    @document_id = document_id
    @user_id = user_id
  end

  def call
    success = valid?

    case_review.update!(document_id: document_id) if success

    FormResponse.new(success: success, errors: errors.messages)
  end

  private

  attr_reader :id, :document_id, :user_id
  attr_writer :user_id

  def case_review
    @case_review ||= AttorneyCaseReview.find_by(id: id)
  end

  def authorized_to_edit
    return if [case_review.attorney_id, case_review.reviewing_judge_id].include?(user_id)

    errors.add(:user_id, "You are not authorized to edit this document ID")
  end

  def correct_format
    return if correct_format?

    errors.add(:document_id, work_product_error_hash[work_product])
  end

  def correct_format?
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

  def work_product
    case_review.work_product
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
      "OMO - VHA" => "VHA Document IDs must must be in one of the these formats: V1234567.123 or V1234567.1234",
      "OMO - IME" => "IME Document IDs must must be in one of the these formats: M1234567.123 or M1234567.1234",
      "Decision" => "Draft Decision Document IDs must be in one of the these formats: " \
                    "12345-12345678 or 12345678.123 or 12345678.1234"
    }
  end
end
