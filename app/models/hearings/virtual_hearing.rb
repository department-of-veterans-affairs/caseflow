# frozen_string_literal: true

class VirtualHearing < CaseflowRecord
  alias_attribute :alias_name, :alias

  belongs_to :hearing, polymorphic: true
  belongs_to :created_by, class_name: "User"

  # Tracks the progress of the job that creates the virtual hearing in Pexip.
  has_one :establishment, class_name: "VirtualHearingEstablishment"

  before_create :assign_created_by_user

  validates :veteran_email, presence: true, on: :create
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

  def all_emails_sent?
    veteran_email_sent &&
      (representative_email.nil? || representative_email_sent)
  end

  def guest_link
    "#{base_url}?conference=#{alias_name}&pin=#{guest_pin}#&join=1&role=guest"
  end

  def host_link
    "#{base_url}?conference=#{alias_name}&pin=#{host_pin}#&join=1&role=host"
  end

  private

  def base_url
    "https://#{ENV['PEXIP_CLIENT_HOST'] || 'localhost'}/webapp/"
  end

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def associated_hearing_is_video
    if hearing.request_type != HearingDay::REQUEST_TYPES[:video]
      errors.add(:hearing, "must be a video hearing")
    end
  end
end
