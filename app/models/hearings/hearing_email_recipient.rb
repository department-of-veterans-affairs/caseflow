# frozen_string_literal: true

class HearingEmailRecipient < CaseflowRecord
  belongs_to :hearing, polymorphic: true
  has_many :email_events, class_name: "SentHearingEmailEvent"

  validates_email_format_of :email_address
  validates :email_address, presence: true

  RECIPIENT_ROLES = {
    appellant: "appellant"
    # representative: "representative",
    # judge: "judge"
  }.freeze

  def email_sent
    # open question: can this be derived?
  end

  def reminder_sent_at
    email_events.where(email_type: "reminder").order(:sent_at).last.sent_at
  end
end
