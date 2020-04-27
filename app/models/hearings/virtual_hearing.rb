# frozen_string_literal: true

class VirtualHearing < CaseflowRecord
  alias_attribute :alias_name, :alias

  belongs_to :hearing, polymorphic: true
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User", optional: true

  # Tracks the progress of the job that creates the virtual hearing in Pexip.
  has_one :establishment, class_name: "VirtualHearingEstablishment"

  before_create :assign_created_by_user
  before_save :assign_updated_by_user

  validates :veteran_email, presence: true, on: :create
  validates_email_format_of :judge_email, allow_nil: true
  validates_email_format_of :veteran_email
  validates_email_format_of :representative_email, allow_nil: true
  validate :associated_hearing_is_video, on: :create

  scope :eligible_for_deletion,
        lambda {
          joins(:establishment)
            .where("
              conference_deleted = false AND (
              request_cancelled = true OR
              virtual_hearing_establishments.processed_at IS NOT NULL
            )")
        }

  scope :not_cancelled,
        -> { where(request_cancelled: false) }

  scope :cancelled,
        -> { where(request_cancelled: true) }

  def all_emails_sent?
    veteran_email_sent &&
      (judge_email.nil? || judge_email_sent) &&
      (representative_email.nil? || representative_email_sent)
  end

  # After a certain point after this change gets merged, alias_with_host will never be nil
  # so we can rid of this logic then
  def formatted_alias_with_host
    alias_with_host.nil? ? "BVA#{alias_name}@#{client_host}" : alias_with_host
  end

  def guest_link
    "#{base_url}?conference=#{formatted_alias_with_host}&pin=#{guest_pin}#&join=1&role=guest"
  end

  def host_link
    "#{base_url}?conference=#{formatted_alias_with_host}&pin=#{host_pin}#&join=1&role=host"
  end

  def job_completed?
    active? && all_emails_sent?
  end

  # Determines if the hearing has been cancelled
  def cancelled?
    status == :cancelled
  end

  # Hearings are pending if the conference is not created and it is not cancelled
  def pending?
    status == :pending
  end

  # Determines if the hearing conference has been created
  def active?
    status == :active
  end

  # Determines the status of the Virtual Hearing based on the establishment
  def status
    # Check if the establishment has been cancelled by the user
    if request_cancelled?
      return :cancelled
    end

    # If the conference has been created the virtual hearing is active
    if conference_id
      return :active
    end

    # If the establishment is not active or cancelled it is pending
    :pending
  end

  # Hearings can be established only if the conference has been created and emails sent
  def can_be_established?
    active? && all_emails_sent?
  end

  def established!
    establishment.clear_error!
    establishment.processed!
    update(request_cancelled: false)
  end

  # Sets the virtual hearing status to cancelled
  def cancel!
    update(request_cancelled: true)
  end

  private

  def client_host
    ENV["PEXIP_CLIENT_HOST"]
  end

  def base_url
    "https://#{client_host || 'localhost'}/bva-app/"
  end

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def assign_updated_by_user
    self.updated_by = RequestStore[:current_user] if RequestStore[:current_user].present?
  end

  def associated_hearing_is_video
    if hearing.request_type != HearingDay::REQUEST_TYPES[:video]
      errors.add(:hearing, "must be a video hearing")
    end
  end
end
