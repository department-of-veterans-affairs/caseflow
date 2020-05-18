# frozen_string_literal: true

class VirtualHearing < CaseflowRecord
  class << self
    def client_host_or_default
      ENV["PEXIP_CLIENT_HOST"] || "care.evn.va.gov"
    end

    def formatted_alias(alias_name)
      "BVA#{alias_name}@#{client_host_or_default}"
    end

    def base_url
      "https://#{client_host_or_default}/bva-app/"
    end
  end

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
  validate :hearing_is_not_virtual, on: :create

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
  def formatted_alias_or_alias_with_host
    alias_with_host.nil? ? VirtualHearing.formatted_alias(alias_name) : alias_with_host
  end

  # Returns a random host and guest pin
  def generate_conference_pins
    self.guest_pin_long = "#{rand(1_000_000_000..9_999_999_999).to_s[0..9]}#"
    self.host_pin_long = "#{rand(1_000_000..9_999_999).to_s[0..9]}#"
  end

  # Override the guest pin
  def guest_pin
    guest_pin_long || self[:guest_pin]
  end

  # Override the host pin
  def host_pin
    host_pin_long || self[:host_pin]
  end

  def guest_link
    "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
    "conference=#{formatted_alias_or_alias_with_host}&" \
    "pin=#{guest_pin}&role=guest"
  end

  def host_link
    "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
    "conference=#{formatted_alias_or_alias_with_host}&" \
    "pin=#{host_pin}&role=host"
  end

  def test_link(title)
    name = if title == MailRecipient::RECIPIENT_TITLES[:representative]
             "Representative"
           elsif hearing&.appeal&.appellant_is_not_veteran
             "Appellant"
           else
             "Veteran"
           end

   "https://care.va.gov/webapp2/conference/test_call?name=#{name}&join=1"
  end

  def job_completed?
    (active? || cancelled?) && all_emails_sent?
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

  def assign_created_by_user
    self.created_by ||= RequestStore.store[:current_user]
  end

  def assign_updated_by_user
    return if RequestStore.store[:current_user] == User.system_user && updated_by.present?

    self.updated_by = RequestStore.store[:current_user] if RequestStore.store[:current_user].present?
  end

  def associated_hearing_is_video
    if hearing.request_type != HearingDay::REQUEST_TYPES[:video]
      errors.add(:hearing, "must be a video hearing")
    end
  end

  def hearing_is_not_virtual
    if hearing.virtual?
      errors.add(:hearing, "hearing is already a virtual hearing")
    end
  end
end
