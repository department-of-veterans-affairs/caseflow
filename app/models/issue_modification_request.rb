# frozen_string_literal: true

class IssueModificationRequest < CaseflowRecord
  has_paper_trail on: [:update, :destroy]

  belongs_to :request_issue
  belongs_to :decision_review, polymorphic: true
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :requestor, presence: true

  validate :open_issue_modification_request, if: proc { |imr| !imr.addition? }

  before_save :set_decided_at

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }

  enum request_type: {
    addition: "addition",
    removal: "removal",
    modification: "modification",
    withdrawal: "withdrawal"
  }

  def serialize
    Intake::IssueModificationRequestSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def self.create_from_params!(attributes, review, user)
    unless attributes[:status].casecmp("assigned").zero?
      fail(
        Caseflow::Error::ErrorCreatingNewRequest,
        message: COPY::ERROR_CREATING_NEW_REQUEST
      )
    end

    create!(
      decision_review: review,
      request_issue_id: attributes[:request_issue_id],
      request_type: attributes[:request_type].downcase,
      request_reason: attributes[:request_reason],
      benefit_type: attributes[:benefit_type],
      decision_date: attributes[:decision_date],
      decision_reason: attributes[:decision_reason],
      nonrating_issue_category: attributes[:nonrating_issue_category],
      nonrating_issue_description: attributes[:nonrating_issue_description],
      status: attributes[:status].downcase,
      requestor: user
    )
  end

  def edit_from_params!(attributes, current_user)
    unless allowed_to_update?(attributes, current_user)
      fail(
        Caseflow::Error::ErrorModifyingExistingRequest,
        message: COPY::ERROR_MODIFYING_EXISTING_REQUEST
      )
    end

    update!(
      nonrating_issue_category: attributes[:nonrating_issue_category],
      decision_date: attributes[:decision_date],
      nonrating_issue_description: attributes[:nonrating_issue_description],
      request_reason: attributes[:request_reason],
      edited_at: Time.zone.now
    )
  end

  def cancel_from_params!(attributes, current_user)
    unless allowed_to_update?(attributes, current_user)
      fail(
        Caseflow::Error::ErrorModifyingExistingRequest,
        message: COPY::ERROR_MODIFYING_EXISTING_REQUEST
      )
    end

    update!(status: "cancelled")
  end

  private

  def open_issue_modification_request
    if request_issue.issue_modification_requests.where.not(id: id).where(status: "assigned").any?
      fail(
        Caseflow::Error::ErrorOpenModifyingExistingRequest,
        message: COPY::ERROR_OPEN_MODIFICATION_EXISTING_REQUEST
      )
    end
  end

  def set_decided_at
    if status_changed? && status_was == "assigned" && decider_id?
      self.decided_at = Time.zone.now
    end
  end

  def allowed_to_update?(attributes, user)
    attributes[:status].casecmp("assigned").zero? && requestor == user
  end
end
