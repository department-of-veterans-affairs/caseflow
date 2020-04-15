# frozen_string_literal: true

class VirtualHearing < CaseflowRecord
  alias_attribute :alias_name, :alias

  belongs_to :hearing, polymorphic: true
  belongs_to :created_by, class_name: "User"

  # Tracks the progress of the job that creates the virtual hearing in Pexip.
  has_one :establishment, class_name: "VirtualHearingEstablishment"

  before_create :assign_created_by_user

  validates :veteran_email, presence: true, on: :create
  validates_email_format_of :judge_email, allow_nil: true
  validates_email_format_of :veteran_email
  validates_email_format_of :representative_email, allow_nil: true
  validate :associated_hearing_is_video, on: :create

  enum status: {
    # Initial status for a virtual hearing. Indicates the Pexip conference
    # does not exist yet
    pending: :pending,

    # Indicates that the Pexip conference was created
    active: :active,

    # Indicates that the hearing was cancelled, and the Pexip conference needs
    # to be cleaned up
    cancelled: :cancelled
  }

  scope :eligible_for_deletion,
        lambda {
          where(
            conference_deleted: false,
            id: select { |hearing| [:active, :cancelled].include?(hearing.status) }.pluck(:id)
          )
        }

  scope :not_cancelled,
        -> { where(id: reject(&:cancelled?).pluck(:id)) }

  scope :cancelled,
        -> { where(id: select(&:cancelled?).pluck(:id)) }

  def all_emails_sent?
    veteran_email_sent &&
      (judge_email.nil? || judge_email_sent) &&
      (representative_email.nil? || representative_email_sent)
  end

  def guest_link
    "#{base_url}?conference=#{alias_name}&pin=#{guest_pin}#&join=1&role=guest"
  end

  def host_link
    "#{base_url}?conference=#{alias_name}&pin=#{host_pin}#&join=1&role=host"
  end

  def job_completed?
    active? && all_emails_sent?
  end

  # Determines if the hearing has been cancelled
  def cancelled?
    status == :cancelled
  end

  # Determines if the hearing is pending
  def pending?
    status == :pending
  end

  # Determines if the hearing has been activated
  def active?
    status == :active
  end

  # Determines the status of the Virtual Hearing based on the establishment
  def status
    # Check if the establishment has been cancelled
    if establishment.canceled?
      return :cancelled
    end

    # If the establishment has been processed it is active
    if establishment.processed?
      return :active
    end

    # If the establishment is not active or cancelled it is pending
    :pending
  end

  # Sets the virtual hearing status to active
  def activate!
    establishment.processed!
  end

  # Sets the virtual hearing status to cancelled
  def cancel!
    establishment.restart!
    establishment.canceled!
  end

  private

  def base_url
    "https://#{ENV['PEXIP_CLIENT_HOST'] || 'localhost'}/bva-app/"
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
