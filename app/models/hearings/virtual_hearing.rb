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
#
# A note about `status`:
#   * Status can be `cancelled`, `closed`, `active`, or `pending` *
#   `cancelled` : Initially virtual hearings could be only created when the hearing coordinator switched the hearing
#                 type (`Video` or `Central`) to virtual. If that type is switched back to the orginal type,
#                 this is tracked by `request_cancelled`. Essentially `cancelled` is derived from `request_cancelled`
#                 and indicates that the hearing type was switched back to original type and **NOT** that
#                 conference was deleted or hearing was cancelled.
#
#   `closed`: This is derived from `conference_deleted` which indicates that we deleted the conference that was created.
#             Though we delete conferences for every virtual hearing after the schedduled date, this helps us
#             distinguish between hearings which types were switched and hearings which were cancelled or postponed
#             because for the latter `request_cancelled` will not be set to `true`.
#
#   `active`: This indicates that the conference was created for a virtual hearing, derived from presence of
#             `conference_id` or presence of `host_hearing_link` and `guest_hearing_link`
#
#   `pending`: This indicates that the conference has yet to be created.
##
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
              conference_deleted = false AND
              conference_id IS NOT NULL AND (
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

  # Whether or not all non-reminder emails were sent.
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
    return guest_hearing_link if guest_hearing_link.present?

    "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
    "conference=#{formatted_alias_or_alias_with_host}&" \
    "pin=#{guest_pin}&role=guest"
  end

  def host_link
    return host_hearing_link if host_hearing_link.present?

    "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
    "conference=#{formatted_alias_or_alias_with_host}&" \
    "pin=#{host_pin}&role=host"
  end

  def test_link(title)
    if use_vc_test_link?
      "https://vc.va.gov/webapp2/conference/test_call?name=#{email_recipient_name(title)}&join=1"
    else
      "https://care.va.gov/webapp2/conference/test_call?name=#{email_recipient_name(title)}&join=1"
    end
  end

  def job_completed?
    (active? || cancelled?) && all_emails_sent?
  end

  # Determines if the hearing type has been switched to the original type
  # NOTE: This can only happen from the hearing details page where the hearing coordinator
  # can switch the type from virtual back to Video or Central. This essentailly cancels
  # this virtual hearing.
  def cancelled?
    # the establishment has been cancelled by the user
    request_cancelled?
  end

  # Hearings are pending if the conference is not created and it is not cancelled
  def pending?
    status == :pending
  end

  # Determines if the hearing conference has been created
  def active?
    # the conference has been created the virtual hearing is active
    conference_id.present? || (guest_hearing_link.present? && host_hearing_link.present?)
  end

  # Determines if the conference was deleted
  # NOTE: Even though the conference is deleted for every virtual hearing,
  # this status helps us distinguish between hearings that had their types
  # switched back to original type and cancelled and postponed hearings which
  # require us to delete the conference but not set `request_cancelled`.
  def closed?
    # the conference has been created the virtual hearing was deleted
    conference_id.present? && conference_deleted?
  end

  # Determines the status of the Virtual Hearing based on the establishment
  def status
    return :cancelled if cancelled?
    return :closed if closed?
    return :active if active?

    # If the establishment is not active, closed, or cancelled it is pending
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

  def use_vc_test_link?
    guest_hearing_link.present? && host_hearing_link.present?
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
