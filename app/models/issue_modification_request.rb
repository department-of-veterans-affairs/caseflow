# frozen_string_literal: true

class IssueModificationRequest < CaseflowRecord
  has_paper_trail on: [:update, :destroy]

  belongs_to :request_issue
  belongs_to :decision_review, polymorphic: true
  belongs_to :requestor, class_name: "User"
  belongs_to :decider, class_name: "User", optional: true

  validates :status, :requestor, presence: true

  validate :only_one_assigned_issue_modification_request, if: :request_issue
  validate :request_issue_exists_unless_addition

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

  def self.attributes_from_form_data(attributes)
    {
      request_issue_id: attributes[:request_issue_id],
      request_type: attributes[:request_type].downcase,
      request_reason: attributes[:request_reason],
      benefit_type: attributes[:benefit_type],
      decision_date: attributes[:decision_date],
      decision_reason: attributes[:decision_reason],
      nonrating_issue_category: attributes[:nonrating_issue_category],
      nonrating_issue_description: attributes[:nonrating_issue_description],
      status: attributes[:status].downcase,
      withdrawal_date: attributes[:withdrawal_date]
    }
  end

  def self.create_from_params!(attributes, review, user)
    unless attributes[:status].casecmp("assigned").zero?
      fail(
        Caseflow::Error::ErrorCreatingNewRequest,
        message: COPY::ERROR_CREATING_NEW_REQUEST
      )
    end

    create_attributes_hash = IssueModificationRequest.attributes_from_form_data(attributes)
      .merge(decision_review: review, requestor: user)

    create!(create_attributes_hash)
  end

  def edit_from_params!(attributes, user)
    unless assigned? && non_admin_allowed_to_update?(user)
      fail(
        Caseflow::Error::ErrorModifyingExistingRequest,
        message: COPY::ERROR_MODIFYING_EXISTING_REQUEST
      )
    end

    update!(edited_attributes(attributes).merge(edited_at: Time.zone.now))
  end

  def cancel_from_params!(user)
    unless assigned? && non_admin_allowed_to_update?(user)
      fail(
        Caseflow::Error::ErrorModifyingExistingRequest,
        message: COPY::ERROR_MODIFYING_EXISTING_REQUEST
      )
    end

    update!(status: "cancelled")
  end

  def deny_request_from_params!(attributes, user)
    unless admin_allowed_to_update?(user)
      fail(
        Caseflow::Error::ErrorDenyingExistingRequest,
        message: COPY::ERROR_DECIDING_ISSUE_MODIFICATION_REQUEST
      )
    end

    denial_attributes = {
      decider: user,
      status: :denied,
      decision_reason: attributes[:decision_reason]
    }.merge(edited_attributes(attributes))

    update!(denial_attributes)
  end

  def approve_request_from_params!(attributes, user)
    unless admin_allowed_to_update?(user)
      fail(
        Caseflow::Error::ErrorApprovingExistingRequest,
        message: COPY::ERROR_DECIDING_ISSUE_MODIFICATION_REQUEST
      )
    end

    approve_attributes = {
      decider: user,
      status: :approved,
      decision_reason: attributes[:decision_reason],
      remove_original_issue: !!attributes[:remove_original_issue]
    }.merge(edited_attributes(attributes))

    update!(approve_attributes)
  end

  private

  def only_one_assigned_issue_modification_request
    if assigned? && request_issue.issue_modification_requests.assigned.where.not(id: id).exists?
      fail(
        Caseflow::Error::ErrorOpenModifyingExistingRequest,
        message: COPY::ERROR_OPEN_MODIFICATION_EXISTING_REQUEST
      )
    end
  end

  def request_issue_exists_unless_addition
    if !addition? && request_issue.nil?
      errors.add(:request_issue, "must exist if request_type is not addition")
    end
  end

  def set_decided_at
    if status_changed? && status_was == "assigned" && decider_id?
      self.decided_at = Time.zone.now
    end
  end

  def non_admin_allowed_to_update?(user)
    assigned? && requestor == user
  end

  def admin_allowed_to_update?(user)
    assigned? && user.vha_business_line_admin_user?
  end

  def edited_attributes(attributes)
    IssueModificationRequest.attributes_from_form_data(attributes).slice(
      :nonrating_issue_category,
      :decision_date,
      :nonrating_issue_description,
      :request_reason,
      :withdrawal_date
    )
  end
end
