# frozen_string_literal: true

class VirtualHearing < ApplicationRecord
  alias_attribute :alias_name, :alias

  belongs_to :hearing, polymorphic: true
  belongs_to :created_by, class_name: "User"

  before_create :assign_created_by_user

  validates :judge_email, presence: true, on: :create
  validates :veteran_email, presence: true, on: :create
  validates_email_format_of :judge_email
  validates_email_format_of :veteran_email
  validates_email_format_of :representative_email, allow_nil: true
  validate :associated_hearing_is_video, on: :create

  enum status: {
    # Initial status for a virtual hearing. Indicates the Pexip conference
    # does not exist yet
    pending: "pending",

    # Indicates that the Pexip conference was created
    active: "active",

    # Indicates that the hearing was cancelled, and the Pexip conference needs
    # to be cleaned up
    cancelled: "cancelled"
  }

  scope :not_cancelled,
        -> { where.not(status: :cancelled) }

  scope :eligible_for_deletion,
        -> { where(conference_deleted: false, status: [:active, :cancelled]) }

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def associated_hearing_is_video
    if hearing.request_type != HearingDay::REQUEST_TYPES[:video]
      errors.add(:hearing, "must be a video hearing")
    end
  end
end
