# frozen_string_literal: true

##
# Model to track the history of virtual hearing emails sent out hearing
# recipients (judge, representative, appellant).

class SentHearingEmailEvent < CaseflowRecord
  include BelongsToPolymorphicHearingConcern
  belongs_to_polymorphic_hearing(:hearing)

  belongs_to :sent_by, class_name: "User"
  belongs_to :email_recipient, class_name: "HearingEmailRecipient"

  has_one :sent_hearing_admin_email_events

  before_create :assign_sent_at_time

  # Allows all keys specified in `MailRecipient::RECIPIENT_TITLES`
  enum recipient_role: HearingEmailRecipient::RECIPIENT_ROLES.keys.map { |key| [key, key.to_s] }.to_h,
       _prefix: :sent_to

  # Overrides the generated method for compatibility with old data prior to:
  #   https://github.com/department-of-veterans-affairs/caseflow/issues/14147
  class << self; undef_method :sent_to_appellant; end
  scope :sent_to_appellant, -> { where(recipient_role: [:veteran, :appellant]) }

  # Email types are specified in `SendEmail#email_for_recipient`
  enum email_type: (
    {
      confirmation: "confirmation",
      cancellation: "cancellation",
      updated_time_confirmation: "updated_time_confirmation",
      reminder: "reminder"
    }
  ), _prefix: :is

  def sent_to_role
    case recipient_role
    when "judge"
      "VLJ Email"
    when "appellant"
      "Appellant Email"
    when "veteran"
      "Veteran Email"
    when "representative"
      "POA/Representative Email"
    else
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "recipient_role",
        message: "recipient_role must be one of #{RECIPIENT_ROLES}, received: #{recipient_role}"
      )
    end
  end

  private

  def assign_sent_at_time
    self.sent_at ||= Time.now.utc
  end
end
