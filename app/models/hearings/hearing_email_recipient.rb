# frozen_string_literal: true

class HearingEmailRecipient < CaseflowRecord
  belongs_to :hearing, polymorphic: true
  has_many :email_events, class_name: "SentHearingEmailEvent", foreign_key: :email_recipient_id

  # AppellantHearingEmailRecipient cannot have nil email address
  validates_email_format_of :email_address, allow_nil: true

  RECIPIENT_ROLES = {
    appellant: "appellant",
    representative: "representative",
    judge: "judge"
  }.freeze

  RECIPIENT_TITLES = {
    judge: "Judge",
    appellant: "Appellant",
    representative: "Representative"
  }.freeze

  def reminder_sent_at
    email_events
      .where(email_type: "reminder", recipient_role: role)
      &.order(:sent_at)
      &.last
      &.sent_at
  end
end
