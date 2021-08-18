# frozen_string_literal: true

class HearingEmailRecipient < CaseflowRecord
  include BelongsToPolymorphicHearingConcern
  belongs_to_polymorphic_hearing(:hearing)

  def self.email_error_message
    fail Caseflow::Error::MustImplementInSubclass
  end

  RECIPIENT_ROLES = {
    appellant: "appellant",
    veteran: "veteran",
    representative: "representative",
    judge: "judge"
  }.freeze

  RECIPIENT_TITLES = RECIPIENT_ROLES.map { |key, role| [key, role.capitalize] }.to_h.freeze

  validates :email_address, presence: true, on: :create
  has_many :email_events, class_name: "SentHearingEmailEvent", foreign_key: :email_recipient_id

  def reminder_sent_at
    email_events
      .where(email_type: "reminder", recipient_role: roles)
      &.order(:sent_at)
      &.last
      &.sent_at
  end

  def roles
    fail Caseflow::Error::MustImplementInSubclass
  end
end
