# frozen_string_literal: true

##
# Virtual hearing is a type of hearing where the veteran/appellant can have a hearing with a VLJ
# by joining a video conference from any device without having to travel to a VA facility.
# Caseflow integrates with a conferencing solution called Pexip to create conference rooms
# and uses GovDelivery to send email notifications to participants of hearing
# which includes the veteran/appellant, judge, and representative.
#
# This model tracks data about the conference rooms as well as the participant email address
# and whether the emails have been sent out. When a hearing coordinator switches a hearing to
# virtual hearing, CreateConferenceJob is kicked off to create a conference and send out
# emails to participants including the link to video conference as well as other details about
# the hearing. DeleteConferencesJob is kicked off to delete the conference resource
# when the the virtual hearing is cancelled or after the hearing takes place.

class VirtualHearing < CaseflowRecord
  include UpdatedByUserConcern

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

  # Tracks the progress of the job that creates the virtual hearing in Pexip.
  has_one :establishment, class_name: "VirtualHearingEstablishment"

  before_create :assign_created_by_user

  validates :appellant_email, presence: true, on: :create
  validates_email_format_of :judge_email, allow_nil: true
  validates_email_format_of :appellant_email
  validates_email_format_of :representative_email, allow_nil: true
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

  VALID_REQUEST_TYPES = [
    HearingDay::REQUEST_TYPES[:video],
    HearingDay::REQUEST_TYPES[:central]
  ].freeze

  def all_emails_sent?
    appellant_email_sent &&
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
    "https://care.va.gov/webapp2/conference/test_call?name=#{email_recipient_name(title)}&join=1"
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

  # checks if emails were sent to appellant and reps
  def cancellation_emails_sent?
    appellant_email_sent && (representative_email.nil? || representative_email_sent)
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore.store[:current_user]
  end

  def hearing_is_not_virtual
    if hearing.virtual?
      errors.add(:hearing, "hearing is already a virtual hearing")
    end
  end

  def email_recipient_name(title)
    if title == MailRecipient::RECIPIENT_TITLES[:representative]
      "Representative"
    elsif hearing&.appeal&.appellant_is_not_veteran
      "Appellant"
    else
      "Veteran"
    end
  end
end
